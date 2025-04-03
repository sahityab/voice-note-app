from xata.client import XataClient
from config import XATA_API_KEY, XATA_DB_URL

client = XataClient(api_key=XATA_API_KEY, db_url=XATA_DB_URL)

def save_note(note):
    client.records().insert("notes", note)
    if note.get("group"):
        client.records().insert("groups", {"name": note["group"]})

def get_all_notes():
    return client.records().get_all("notes")

def get_all_groups():
    return client.records().get_all("groups")
