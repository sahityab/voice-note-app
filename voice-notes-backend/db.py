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

def get_all_notes(page_size: int = 100):
    response = client.data().query("notes", {
        "sort": { "xata_createdat": "desc" }, 
        "page": {"size": page_size}
        })
    return response["records"]

def get_all_groups():
    response = client.data().query("groups", {"page": {"size": 100}})
    return response["records"]
    