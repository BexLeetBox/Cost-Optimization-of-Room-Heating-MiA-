from flask import Flask, jsonify, request, render_template, send_file
from flask_cors import CORS
import requests
import pytz
import pandas as pd
from datetime import datetime
import subprocess
import os

app = Flask(__name__)
CORS(app)

NORWAY_TZ = pytz.timezone("Europe/Oslo")

UPLOAD_FOLDER = "uploads"
OUTPUT_FOLDER = "outputs"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)


@app.route('/')
def home():
    return render_template('index.html')

def convert_to_norway_time(timestamp):
    """Convert UTC time to Norway time (CET/CEST)."""
    return pd.to_datetime(timestamp).tz_convert(NORWAY_TZ)

def fetch_energy_prices():
    """Fetches energy prices for the current day and converts time to Norway timezone."""
    # Get today's date in Norway timezone
    now = datetime.now(pytz.timezone("Europe/Oslo"))
    today_str = now.strftime("%Y/%m-%d")  # Format as YYYY/MM-DD

    # Update API URL with today's date
    url = f"https://www.hvakosterstrommen.no/api/v1/prices/{today_str}_NO5.json"

    response = requests.get(url)
    if response.status_code != 200:
        return None, {"error": f"Failed to retrieve energy prices for {today_str}"}
    
    energy_data = response.json()
    for entry in energy_data:
        entry["time_start"] = pd.to_datetime(entry["time_start"]).tz_convert("UTC")  # Convert to UTC
    
    return energy_data, None


def fetch_weather_data(lat, lon):
    """Fetches weather data and converts time to Norway timezone."""
    url = f"https://api.met.no/weatherapi/locationforecast/2.0/compact?lat={lat}&lon={lon}"
    headers = {"User-Agent": "MyWeatherApp/1.0"}
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        return None, {"error": "Failed to retrieve weather data"}
    
    weather_data = response.json()
    weather_records = []
    for entry in weather_data["properties"]["timeseries"]:
        time = pd.to_datetime(entry["time"]).tz_convert(NORWAY_TZ)
        temperature = entry["data"]["instant"]["details"].get("air_temperature", None)
        weather_records.append({"time": time, "air_temperature": temperature})
    
    return weather_records, None

@app.route('/merged-data', methods=['GET'])
def get_merged_data():
    """Fetches and merges energy prices with weather data based on time."""
    lat = request.args.get('lat')
    lon = request.args.get('lon')
    if not lat or not lon:
        return jsonify({"error": "Please provide 'lat' and 'lon' query parameters."}), 400
    
    # Fetch data using the correct helper functions
    energy_data, energy_error = fetch_energy_prices()
    weather_data, weather_error = fetch_weather_data(lat, lon)
    
    if energy_error:
        return jsonify(energy_error), 500
    if weather_error:
        return jsonify(weather_error), 500
    
    # Convert to DataFrames
    df_energy = pd.DataFrame(energy_data)
    df_weather = pd.DataFrame(weather_data)


    
    # Merge on time
    df_merged = pd.merge(df_energy, df_weather, left_on="time_start", right_on="time", how="inner")
    
    # Convert back to JSON
    merged_data = df_merged[["time_start", "NOK_per_kWh", "EUR_per_kWh", "air_temperature"]].to_dict(orient="records")
    
    return jsonify(merged_data)


@app.route("/convert-to-msh", methods=["POST"])
def convert_to_msh():
    data = request.json
    geo_file = data.get("geoFile", "layout.geo")

    geo_path = os.path.join(UPLOAD_FOLDER, geo_file)
    msh_path = os.path.join(OUTPUT_FOLDER, "layout.msh")

    # Run Gmsh to generate the .msh file
    subprocess.run(["gmsh", "-2", geo_path, "-o", msh_path], check=True)

    return jsonify({"mshUrl": f"/download-msh"})

@app.route("/download-msh", methods=["GET"])
def download_msh():
    return send_file(os.path.join(OUTPUT_FOLDER, "layout.msh"), as_attachment=True)


@app.route('/run-simulation', methods=['GET'])
def run_simulation():
    """Runs the OpenModelica heat conduction simulation."""
    script_path = os.path.join(os.getcwd(), "run_simulation.py")
    result = subprocess.run(["python", script_path], capture_output=True, text=True)

    if result.returncode == 0:
        return jsonify({"status": "success", "message": "Simulation completed!"})
    else:
        return jsonify({"status": "error", "message": result.stderr}), 500



if __name__ == '__main__':
    app.run(debug=True)