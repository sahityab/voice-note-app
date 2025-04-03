from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from sentence_transformers import SentenceTransformer
from datetime import datetime
import torch
import re
import whisper
import tempfile

tokenizer = AutoTokenizer.from_pretrained("sshleifer/distilbart-cnn-12-6")
model = AutoModelForSeq2SeqLM.from_pretrained("sshleifer/distilbart-cnn-12-6")
embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
whisper_model = whisper.load_model("base")

def summarize(text):
    inputs = tokenizer([text], max_length=1024, return_tensors="pt", truncation=True)
    summary_ids = model.generate(inputs["input_ids"], max_length=100, min_length=10, length_penalty=2.0)
    return tokenizer.decode(summary_ids[0], skip_special_tokens=True)

def detect_reminder(text):
    match = re.search(r'remind me (?:to|about)? (.*?) (?:at|on|by) (\d{1,2}:\d{2}(?:\s?[ap]m)?)', text, re.IGNORECASE)
    if match:
        task, time_str = match.groups()
        return {"task": task, "time": time_str}
    return None

def process_note(text):
    return {
        "id": datetime.utcnow().isoformat(),
        "text": text,
        "summary": summarize(text),
        "timestamp": datetime.utcnow().isoformat(),
        "group": detect_group(text),
        "reminder_time": detect_reminder(text)["time"] if detect_reminder(text) else None
    }

def detect_group(text):
    # Simple placeholder rule for group detection
    if "work" in text.lower():
        return "Work"
    if "idea" in text.lower():
        return "Ideas"
    if "personal" in text.lower():
        return "Personal"
    return "General"

def transcribe_audio(file):
    with tempfile.NamedTemporaryFile(suffix=".webm", delete=True) as tmp:
        file.save(tmp.name)
        result = whisper_model.transcribe(tmp.name)
        return result["text"]
