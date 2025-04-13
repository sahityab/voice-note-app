from flask import Flask, request, jsonify
from flask_cors import CORS
from routes import register_routes
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='[%(levelname)s] %(message)s'
)

app = Flask(__name__)
CORS(app)

register_routes(app)

if __name__ == "__main__":
    app.run(debug=True, port=5001)

