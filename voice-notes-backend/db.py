from xata.client import XataClient
from config import XATA_API_KEY, XATA_DB_URL

client = XataClient(api_key=XATA_API_KEY, db_url=XATA_DB_URL)

def save_note(note):
    try:
        print("[DEBUG] Inserting note to Xata:", note)
        client.records().insert("notes", note)
        print("[DEBUG] Inserted successfully")

        if note.get("group"):
            client.records().insert("groups", {"name": note["group"]})
    except Exception as e:
        print("[ERROR] Failed to insert note:", str(e))

def get_all_notes():
    return client.records().get_all("notes")

def get_all_groups():
    return client.records().get_all("groups")
