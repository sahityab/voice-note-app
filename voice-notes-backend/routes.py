from flask import request, jsonify
from flask_cors import CORS, cross_origin
from logic import process_note
from logic import transcribe_audio as run_transcription
from db import save_note, get_all_notes, get_all_groups

def register_routes(app):
    @app.route("/add_note", methods=["POST"])
    @cross_origin(origins="*")
    def add_note():
        data = request.json
        result = process_note(data.get("text"))
        save_note(result)
        return jsonify(result)

    @app.route("/notes", methods=["GET"])
    @cross_origin(origins="*")
    def get_notes():
        return jsonify(get_all_notes())

    @app.route("/groups", methods=["GET"])
    @cross_origin(origins="*")
    def get_groups():
        return jsonify(get_all_groups())

    @app.route("/transcribe_audio", methods=["POST", 'OPTIONS'])
    @cross_origin(origins="*")
    def transcribe_audio():
        if request.method == 'OPTIONS':
            return '', 204  # respond to preflight without error
        if 'audio' not in request.files:
            return jsonify({"error": "No audio file provided"}), 400
        file = request.files['audio']
        
        transcript = run_transcription(file)  # <- this avoids the name clash
        return jsonify({"transcript": transcript})
        
