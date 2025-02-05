from flask import Flask, jsonify, request
import requests

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message": "Welcome to the Flask application!"})

@app.route('/items/<int:item_id>', methods=['GET'])
def get_item(item_id):
    q = request.args.get('q')
    return jsonify({"item_id": item_id, "q": q})

@app.route('/items', methods=['POST'])
def create_item():
    item = request.get_json()
    return jsonify({"item_name": item.get('name'), "item_price": item.get('price')})

@app.route('/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    item = request.get_json()
    return jsonify({"item_id": item_id, "item": item})

@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    return jsonify({"message": f"Item with id {item_id} has been deleted"})

@app.route('/energy-prices', methods=['GET'])
def get_energy_prices():
    url = "https://www.hvakosterstrommen.no/api/v1/prices/2025/02-05_NO5.json"
    response = requests.get(url)
    if response.status_code == 200:
        return jsonify(response.json())
    else:
        return jsonify({"error": "Failed to retrieve data"}), response.status_code

if __name__ == '__main__':
    app.run(debug=True)