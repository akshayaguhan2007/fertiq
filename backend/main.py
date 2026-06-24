from fastapi import FastAPI
import ee
import firebase_admin
from firebase_admin import credentials

app = FastAPI(title="Carbon Tech API")

# Initialize Firebase Admin
# cred = credentials.Certificate("serviceAccountKey.json")
# firebase_admin.initialize_app(cred)

# Initialize Earth Engine
# ee.Initialize()

@app.get("/health")
def health():
    return {"status": "ok"}
