#from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from sentence_transformers import SentenceTransformer
from datetime import datetime
import torch
import re
import whisper
import tempfile
from collections import defaultdict
from deepmultilingualpunctuation import PunctuationModel
from transformers import (
    T5ForConditionalGeneration, 
    T5Tokenizer,
    PegasusForConditionalGeneration, 
    PegasusTokenizer,
    BartForConditionalGeneration,
    BartTokenizer,
    LEDForConditionalGeneration,
    LEDTokenizer
)
import torch
import re
import requests
import json


OLLAMA_API_URL = "http://localhost:11434/api/generate"


# A small set of common meta-commentary prefixes to stop on
STOP_PHRASES = [
    "This bullet point summary conveys",
    "Let me know if you need anything else",
    "In summary",
    "In conclusion",
    "These key points",
    "The above points",
    "Helpful summary",
    "\n\n"
]

# tokenizer = AutoTokenizer.from_pretrained("sshleifer/distilbart-cnn-12-6")
# model = AutoModelForSeq2SeqLM.from_pretrained("sshleifer/distilbart-cnn-12-6")

#tokenizer = AutoTokenizer.from_pretrained("t5-base")
#model = AutoModelForSeq2SeqLM.from_pretrained("t5-base")
#embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
whisper_model = whisper.load_model("medium")


# Step 1: Load models
punctuation_model = PunctuationModel()  # Punctuation restoration

# MPS/CPU device selection
device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

# Load FLAN-T5-XL
flan_tokenizer = T5Tokenizer.from_pretrained("google/flan-t5-xl")
flan_model = T5ForConditionalGeneration.from_pretrained("google/flan-t5-xl").to(device)

# Load Pegasus model and tokenizer
pegasus_tokenizer = PegasusTokenizer.from_pretrained("google/pegasus-large")
pegasus_model = PegasusForConditionalGeneration.from_pretrained("google/pegasus-large").to(device)


# Load BART model and tokenizer
bart_tokenizer = BartTokenizer.from_pretrained("facebook/bart-large-cnn")
bart_model = BartForConditionalGeneration.from_pretrained("facebook/bart-large-cnn").to(device)

# Load LED model and tokenizer
led_tokenizer = LEDTokenizer.from_pretrained("allenai/led-base-16384")
led_model = LEDForConditionalGeneration.from_pretrained("allenai/led-base-16384").to(device)

# Step 2: Filler removal function
def remove_fillers(text):
    fillers = [
        r"\byou know\b", r"\bi mean\b", r"\byeah\b", r"\bokay\b", 
        r"\bum\b", r"\buh\b", r"\blike\b", r"\bso\b", r"\bwell\b"
    ]
    for filler in fillers:
        text = re.sub(filler, "", text, flags=re.IGNORECASE)
    text = re.sub(r'\s+', ' ', text).strip()  # Remove extra spaces
    return text

# Step 3: Bullet formatting function (runs at the end, post-processing)
def bullet_format(summary):
    lines = summary.split('\n')
    formatted = []
    for line in lines:
        if line.strip().startswith("•"):
            formatted.append(line.strip())  
        else:
            sentences = [s.strip() for s in line.split('. ') if s]
            for s in sentences:
                formatted.append(f"• {s.rstrip('.')}")
        formatted.append("\n")
    return '\n'.join(formatted)

# Step 4: Full pipeline function
def process_text(text):
    # Filler removal
    cleaned_transcript = remove_fillers(text)
    
    # Punctuation restoration
    punctuated_text = punctuation_model.restore_punctuation(cleaned_transcript)
    
     # Token count using BART tokenizer
    bart_tokens = bart_tokenizer(punctuated_text, return_tensors="pt", truncation=False)
    token_count = bart_tokens['input_ids'].shape[1]
 
    # Short input handling
    if token_count < 10:
        summary = punctuated_text  # No summarization, just return cleaned text
    elif token_count < 30:
        # Adjust prompt and summarizer settings for short input
        prompt_text = f"Rephrase the following text clearly and consisely:\n{punctuated_text}"
        inputs = bart_tokenizer([prompt_text], max_length=256, return_tensors="pt", truncation=True).to(device)
        summary_ids = bart_model.generate(inputs["input_ids"], max_length=50, min_length=5, length_penalty=2.0, num_beams=4)
        summary_text = bart_tokenizer.decode(summary_ids[0], skip_special_tokens=True)
        summary = bullet_format(summary_text)  # Always bullet format at the end
    elif token_count < 1024:
        # Use Pegasus for medium inputs
        #prompt_text = f"Summarize the following text into concise multiple bullet points that capture the key ideas clearly and briefly:\n\n{punctuated_text}"
        #inputs = flan_tokenizer(prompt_text, max_length=1024, return_tensors="pt", truncation=True).to(device)
        #summary_ids = flan_model.generate(inputs["input_ids"], max_length=150, min_length=20, length_penalty=2.0, num_beams=4, no_repeat_ngram_size=3)
        #summary_text = flan_tokenizer.decode(summary_ids[0], skip_special_tokens=True)
        summary_text = summarize_with_parm2(punctuated_text)
        summary = bullet_format(summary_text)
    else:
        # Use LED for longer inputs
        prompt_text = f"Summarize the following text into bullet points:\n{punctuated_text}"
        inputs = led_tokenizer(
            prompt_text,
            return_tensors="pt",
            max_length=16384,
            truncation=True
        ).to(device)

        global_attention_mask = torch.zeros_like(inputs["input_ids"])
        global_attention_mask[:, 0] = 1  # Set global attention on <s> token

        summary_ids = led_model.generate(
            input_ids=inputs["input_ids"],
            attention_mask=inputs["attention_mask"],
            global_attention_mask=global_attention_mask,
            max_length=512,
            min_length=100,
            length_penalty=2.0,
            num_beams=4
        )
        summary_text = led_tokenizer.decode(summary_ids[0], skip_special_tokens=True)
        summary = bullet_format(summary_text)

    return summary
    
def summarize_with_parm2(note_text):
    """   prompt = (
        "Summarize the following text into a few concise key points in simple words "
        "(preferably 3-4), without any additional metadata:\n\n"
        f"{note_text}"
    ) """
    system_prompt = """<|im_start|>system
    You are an AI assistant that summarizes notes into exactly 3–4 concise bullet points,
    capturing the most critical information, and nothing else.
    <|im_end|>"""

    user_prompt = f"""<|im_start|>user
    Summarize this note into 3–4 bullet points, no extra commentary:
    {note_text}
    <|im_end|><|im_start|>assistant
    """

    full_prompt = system_prompt + "\n\n" + user_prompt
    try:
        # Send the request to the Ollama API
        response = requests.post(
            OLLAMA_API_URL, 
            json={
                "model": "parm2",  # Model name you created in Ollama
                "prompt": full_prompt,
                "stream": False,
                "options": {
                    "num_predict": 256,  # Token limit
                    "stop": STOP_PHRASES
                 }
            },
            timeout=30
        )
        response.raise_for_status()  # Raise an error for bad responses
        data = response.json()
        summary = data.get("response", "")

        return summary
    except Exception as e:
        # Log or handle error appropriately
        print(f"[summarize_with_parm2] error: {e}")
        return "Sorry, I couldn't generate a summary right now."


""" def summarize(text):
    text = "summarize: " + text
    inputs = tokenizer([text], max_length=1024, return_tensors="pt", truncation=True)
    summary_ids = model.generate(inputs["input_ids"], max_length=100, min_length=5, length_penalty=2.0)
    return tokenizer.decode(summary_ids[0], skip_special_tokens=True)
 """
def detect_reminder(text):
    match = re.search(r'remind me (?:to|about)? (.*?) (?:at|on|by) (\d{1,2}:\d{2}(?:\s?[ap]m)?)', text, re.IGNORECASE)
    if match:
        task, time_str = match.groups()
        return {"task": task, "time": time_str}
    return None

def process_note(text):
    reminder_info = detect_reminder(text)
    #summary = process_text(text)
    return {
        "original_text": text,
        "summary": process_text(text),
        "timestamp": datetime.utcnow().isoformat(),
        "group": detect_group(text),
        "is_reminder": bool(reminder_info),
        "device_id": "demo-device-uuid",   # Replace with real UUID later
        "user_id": "unknown"
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

def group_notes_by_group_name(notes):
    grouped_notes = defaultdict(list)
    for note in notes:
        group_name = note.get('fields', {}).get('group')
        grouped_notes[group_name].append(note)
    return grouped_notes

