from flask import Flask, jsonify, request, render_template, send_file
from flask_cors import CORS
import requests
import pytz
import pandas as pd
from datetime import datetime
import subprocess
import os
import json
import socket
import time

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
@app.route('/energy-prices', methods=['GET'])
def fetch_energy_prices(region_code):
    """Fetches energy prices for the current day and converts time to Norway timezone."""
    # Get today's date in Norway timezone
    now = datetime.now(pytz.timezone("Europe/Oslo"))
    today_str = now.strftime("%Y/%m-%d")  # Format as YYYY/MM-DD

    region_code = request.args.get('region_code', 'NO5')  # Default to NO5 if not provided

    # Update API URL with today's date and region code
    #url = f"https://www.hvakosterstrommen.no/api/v1/prices/{today_str}_{region_code}.json"
    url = f"https://www.hvakosterstrommen.no/api/v1/prices/{today_str}_{region_code}.json"

    response = requests.get(url)
    if response.status_code != 200:
        return None, {"error": f"Failed to retrieve energy prices for {today_str} in region {region_code}"}
    
    energy_data = response.json()
    for entry in energy_data:
        entry["time_start"] = pd.to_datetime(entry["time_start"]).tz_convert("UTC")  # Convert to UTC
    
    return energy_data, None



@app.route('/weather-data', methods=['GET'])
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
        temperature = entry["data"]["instant"]["details"].get("air_temperature", None)+273.15
        weather_records.append({"time": time, "air_temperature": temperature})
    
    return weather_records, None

@app.route('/merged-data', methods=['GET'])
def get_merged_data():
    """Fetches and merges energy prices with weather data based on time."""
    lat = request.args.get('lat')
    lon = request.args.get('lon')
    print(request.args.get('region_code'))
    region_code = request.args.get('region_code', 'NO5')  # Default to NO5 if not provided
    if not lat or not lon:
        return jsonify({"error": "Please provide 'lat' and 'lon' query parameters."}), 400
    
    # Fetch data using the correct helper functions
    energy_data, energy_error = fetch_energy_prices(region_code)
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
    geo_content = data.get("geoContent", "")  # Expecting file content
    geo_filename = data.get("geoFile", "layout.geo")

    geo_path = os.path.join(UPLOAD_FOLDER, geo_filename)
    msh_path = os.path.join(OUTPUT_FOLDER, "layout.msh")

    try:
        if not geo_content:
            return jsonify({"error": "No .geo content received"}), 400

        # Save .geo file
        with open(geo_path, "w") as geo_file:
            geo_file.write(geo_content)

        print(f" Saved {geo_filename} in {UPLOAD_FOLDER}/")

        # Run Gmsh with absolute paths
        gmsh_path = r"C:\Users\Bex\AppData\Local\Microsoft\WinGet\Links\gmsh.exe"  # Ensure this is correct
        result = subprocess.run(
            [gmsh_path, "-2", geo_path, "-o", msh_path],
            check=True,
            capture_output=True,
            text=True
        )

        print(f" Gmsh Output: {result.stdout}")
        print(f" Gmsh Errors: {result.stderr}")

        return jsonify({"mshUrl": "/download-msh"})

    except subprocess.CalledProcessError as e:
        print(f" Gmsh failed with error:\n{e.stderr}")
        return jsonify({"error": f"Gmsh failed: {e.stderr}"}), 500
    except Exception as e:
        print(f" Unexpected error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/download-msh", methods=["GET"])
def download_msh():
    msh_file_path = os.path.join(OUTPUT_FOLDER, "layout.msh")
    if not os.path.exists(msh_file_path):
        return jsonify({"error": "No .msh file found"}), 404

    return send_file(msh_file_path, as_attachment=True)

@app.route('/run-simulation', methods=['POST'])
def run_simulation():
    # 1) Persist Boundary.json
    boundary_data = request.json.get('boundary')
    if boundary_data is None:
        return jsonify({"error": "Boundary data missing"}), 400
    with open("Boundary.json", "w") as f:
        json.dump(boundary_data, f, indent=2)

    # 2) Persist WeatherandEnergy.json (if any)
    weather_energy = request.json.get('weatherEnergy')
    if weather_energy is not None:
        with open("WeatherandEnergy.json", "w") as f:
            json.dump(weather_energy, f, indent=2)

    # 3) Launch Julia synchronously
    try:
        subprocess.run(
            ["julia", "main3beka.jl"],
            check=True, capture_output=True, text=True
        )
    except subprocess.CalledProcessError as e:
        return jsonify({"error": e.stderr}), 500

    # 4) Verify results.pvd exists
    output_path = "results.pvd"
    if not os.path.exists(output_path):
        return jsonify({"error": "results.pvd not found after simulation"}), 500

    # 5) Start the ParaView visualizer
    pv_proc = subprocess.Popen(
        ["pvpython", "--venv", ".pvenv", "./pvd-visualizer.py"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )

    # 6) Poll localhost:8080 until it’s up (timeout ~15 s)
    for _ in range(30):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            if sock.connect_ex(("localhost", 8080)) == 0:
                break
        time.sleep(0.5)
    else:
        # if we never broke out of the loop
        return jsonify({
            "status": "error",
            "error": "Visualizer server failed to start on port 8080"
        }), 500

    # 7) All set—return plots + visualizer URL
    return jsonify({
        "status":            "success",
        "output":            output_path,
        "plot":              "price_real_result_beka.png",
        "plot":             "/static/images/price_real_result_beka.png",
        "convergence_plot": "/static/images/price_real_convergence_beka.png",
        "visualizer_url":    "http://localhost:8080/index.html"

    })



if __name__ == '__main__':
    app.run(debug=True)