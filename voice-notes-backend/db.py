from xata.client import XataClient
from config import XATA_API_KEY, XATA_DB_URL
import logging

client = XataClient(api_key=XATA_API_KEY, db_url=XATA_DB_URL)

def save_note(note):
    try:
        logging.debug("Inserting note to Xata: %s", note)
        result = client.records().insert("notes", note)
        logging.debug("Inserted successfully: %s", result)

        if note.get("group"):
            client.records().insert("groups", {"name": note["group"]})
    except Exception as e:
        logging.error("Failed to insert note: %s", str(e))

def get_all_notes():
    return client.records().get_all("notes")

def get_all_groups():
    return client.records().get_all("groups")
