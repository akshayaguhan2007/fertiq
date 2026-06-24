# Carbon Tech

A carbon monitoring and trading platform built with Flutter, Firebase, and Google Earth Engine.

## Structure

```
├── app/          # Flutter mobile/web app
├── backend/      # Python FastAPI + Earth Engine
├── functions/    # Firebase Cloud Functions (Node.js)
└── firebase.json # Firebase project config
```

## Setup

### Flutter App
```bash
cd app && flutter pub get && flutter run
```

### Python Backend
```bash
cd backend
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env   # fill in your values
uvicorn main:app --reload
```

### Cloud Functions
```bash
cd functions && npm install
firebase deploy --only functions
```

## Prerequisites
- Flutter SDK
- Python 3.10+
- Node.js 20+
- Firebase CLI (`npm install -g firebase-tools`)
- Google Earth Engine account
