import os
from dotenv import load_dotenv

load_dotenv()

XATA_API_KEY = os.getenv("XATA_API_KEY")
XATA_DB_URL = os.getenv("XATA_DB_URL")