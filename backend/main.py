from __future__ import annotations  # noqa: F401 – keeps | syntax working on Py3.9
import os, sqlite3, hashlib, secrets, datetime
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv

from carbon_engine import CarbonCalculator
from sensor_simulator import SensorSimulator

try:
    from earth_engine_utils import initialize_earth_engine, get_ndvi_for_farm, get_climate_risks
    _EE_AVAILABLE = True
except Exception:
    _EE_AVAILABLE = False

load_dotenv()

DB_PATH = os.getenv("DB_PATH", "cropplus.db")
JWT_SECRET = os.getenv("JWT_SECRET", secrets.token_hex(32))


# ── Database ──────────────────────────────────────────────────────────────────

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id        TEXT PRIMARY KEY,
            email     TEXT UNIQUE NOT NULL,
            name      TEXT,
            phone     TEXT,
            password  TEXT NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS tokens (
            token     TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            expires_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS farmers (
            user_id           TEXT PRIMARY KEY,
            name              TEXT,
            phone             TEXT,
            village           TEXT,
            district          TEXT,
            farm_size         REAL,
            crops             TEXT,
            preferred_language TEXT DEFAULT 'en',
            join_date         TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS farms (
            id        TEXT PRIMARY KEY,
            farmer_id TEXT NOT NULL,
            name      TEXT,
            soil_type TEXT,
            lat       REAL,
            lng       REAL,
            area      REAL,
            boundary  TEXT,
            crops     TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS analyses (
            id           TEXT PRIMARY KEY,
            farm_id      TEXT NOT NULL,
            farmer_id    TEXT,
            crop_type    TEXT,
            growth_stage TEXT,
            timestamp    TEXT DEFAULT (datetime('now')),
            gpr          REAL DEFAULT 0,
            health_score REAL DEFAULT 0,
            ndvi         REAL DEFAULT 0,
            soil         TEXT,
            carbon       TEXT,
            recommendations TEXT,
            image_url    TEXT,
            source       TEXT DEFAULT 'hardware',
            simulated    INTEGER DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS carbon_credits (
            id         TEXT PRIMARY KEY,
            farmer_id  TEXT NOT NULL,
            farm_id    TEXT NOT NULL,
            amount     REAL DEFAULT 0,
            status     TEXT DEFAULT 'pending',
            sale_price REAL,
            sold_date  TEXT,
            payment_id TEXT
        );
        CREATE TABLE IF NOT EXISTS climate_alerts (
            id              TEXT PRIMARY KEY,
            farm_id         TEXT NOT NULL,
            type            TEXT,
            severity        TEXT,
            risk_percentage REAL,
            recommendation  TEXT,
            created_at      TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS payments (
            id         TEXT PRIMARY KEY,
            credit_id  TEXT NOT NULL,
            farmer_id  TEXT NOT NULL,
            farm_id    TEXT NOT NULL,
            amount     REAL DEFAULT 0,
            payment_id TEXT,
            status     TEXT DEFAULT 'pending',
            created_at TEXT DEFAULT (datetime('now'))
        );
    """)
    conn.commit()
    conn.close()


# ── Auth helpers ──────────────────────────────────────────────────────────────

def _hash(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()


def _new_token(user_id: str) -> str:
    token = secrets.token_urlsafe(32)
    expires = (datetime.datetime.utcnow() + datetime.timedelta(days=30)).isoformat()
    conn = get_db()
    conn.execute("INSERT INTO tokens VALUES (?,?,?)", (token, user_id, expires))
    conn.commit()
    conn.close()
    return token


def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization[7:]
    conn = get_db()
    row = conn.execute(
        "SELECT user_id, expires_at FROM tokens WHERE token=?", (token,)
    ).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=401, detail="Invalid token")
    if datetime.datetime.fromisoformat(row["expires_at"]) < datetime.datetime.utcnow():
        raise HTTPException(status_code=401, detail="Token expired")
    return row["user_id"]


# ── Lifespan ──────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    if _EE_AVAILABLE:
        try:
            initialize_earth_engine()
        except Exception as e:
            print(f"[WARN] Earth Engine init skipped: {e}")
    yield


app = FastAPI(title="AgriCarbon+ API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


# ── Schemas ───────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: str
    password: str
    name: str = ""

class LoginRequest(BaseModel):
    email: str
    password: str

class ProfileRequest(BaseModel):
    name: str
    phone: str
    village: str
    district: str
    farm_size: float
    crops: list[str]
    preferred_language: str = "en"

class FarmRequest(BaseModel):
    name: str
    soil_type: str = ""
    lat: float = 0
    lng: float = 0
    area: float = 0
    boundary: dict = {}
    crops: list[str] = []

class AnalyseRequest(BaseModel):
    farm_id: str
    boundary: dict
    start_date: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    end_date: str   = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    crop_type: str  = ""
    growth_stage: str = ""

class ClimateRequest(BaseModel):
    farm_id: str
    boundary: dict
    days_back: int = Field(default=30, ge=7, le=90)

class FertilizerRequest(BaseModel):
    farm_id: str
    soil: dict
    crop_type: str
    target_yield: float = Field(gt=0)
    area_ha: float = Field(default=1.0, gt=0)

class SimulateRequest(BaseModel):
    farm_id: str
    crop_type: str = ""
    soil_type: str = ""
    area_ha: float = Field(default=1.0, gt=0)
    days: int = Field(default=0, ge=0, le=90)
    seed: int | None = None

class SensorReadingRequest(BaseModel):
    farm_id: str
    n: float = Field(ge=0, le=500)
    p: float = Field(ge=0, le=200)
    k: float = Field(ge=0, le=600)
    moisture: float    = Field(ge=0, le=100)
    temperature: float = Field(ge=-10, le=60)
    ec: float          = Field(ge=0, le=10)
    ph: float          = Field(ge=3, le=10)
    timestamp: str | None = None
    source: str = "hardware"


# ── Auth routes ───────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/auth/register")
def register(req: RegisterRequest):
    import uuid
    conn = get_db()
    if conn.execute("SELECT id FROM users WHERE email=?", (req.email,)).fetchone():
        conn.close()
        raise HTTPException(status_code=400, detail="Email already registered")
    user_id = str(uuid.uuid4())
    conn.execute(
        "INSERT INTO users (id, email, name, password) VALUES (?,?,?,?)",
        (user_id, req.email, req.name, _hash(req.password))
    )
    conn.commit()
    conn.close()
    token = _new_token(user_id)
    return {"user_id": user_id, "token": token, "email": req.email, "name": req.name}


@app.post("/auth/login")
def login(req: LoginRequest):
    conn = get_db()
    row = conn.execute(
        "SELECT id, name, email FROM users WHERE email=? AND password=?",
        (req.email, _hash(req.password))
    ).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    token = _new_token(row["id"])
    return {"user_id": row["id"], "token": token, "email": row["email"], "name": row["name"]}


@app.post("/auth/logout")
def logout(authorization: Optional[str] = Header(None)):
    if authorization and authorization.startswith("Bearer "):
        token = authorization[7:]
        conn = get_db()
        conn.execute("DELETE FROM tokens WHERE token=?", (token,))
        conn.commit()
        conn.close()
    return {"status": "ok"}


# ── Profile routes ────────────────────────────────────────────────────────────

@app.get("/profile")
def get_profile(user_id: str = Depends(get_current_user)):
    conn = get_db()
    row = conn.execute("SELECT * FROM farmers WHERE user_id=?", (user_id,)).fetchone()
    conn.close()
    if not row:
        return {"exists": False}
    import json
    return {"exists": True, **dict(row), "crops": json.loads(row["crops"] or "[]")}


@app.post("/profile")
def save_profile(req: ProfileRequest, user_id: str = Depends(get_current_user)):
    import json
    conn = get_db()
    conn.execute("""
        INSERT INTO farmers (user_id, name, phone, village, district, farm_size, crops, preferred_language)
        VALUES (?,?,?,?,?,?,?,?)
        ON CONFLICT(user_id) DO UPDATE SET
            name=excluded.name, phone=excluded.phone, village=excluded.village,
            district=excluded.district, farm_size=excluded.farm_size,
            crops=excluded.crops, preferred_language=excluded.preferred_language
    """, (user_id, req.name, req.phone, req.village, req.district,
          req.farm_size, json.dumps(req.crops), req.preferred_language))
    conn.commit()
    conn.close()
    return {"status": "ok"}


# ── Farm routes ───────────────────────────────────────────────────────────────

@app.get("/farms")
def get_farms(user_id: str = Depends(get_current_user)):
    import json
    conn = get_db()
    rows = conn.execute("SELECT * FROM farms WHERE farmer_id=?", (user_id,)).fetchall()
    conn.close()
    return [{ **dict(r), "crops": json.loads(r["crops"] or "[]"),
              "boundary": json.loads(r["boundary"] or "{}") } for r in rows]


@app.post("/farms")
def create_farm(req: FarmRequest, user_id: str = Depends(get_current_user)):
    import uuid, json
    farm_id = str(uuid.uuid4())
    conn = get_db()
    conn.execute(
        "INSERT INTO farms (id, farmer_id, name, soil_type, lat, lng, area, boundary, crops) VALUES (?,?,?,?,?,?,?,?,?)",
        (farm_id, user_id, req.name, req.soil_type, req.lat, req.lng,
         req.area, json.dumps(req.boundary), json.dumps(req.crops))
    )
    conn.commit()
    conn.close()
    return {"farm_id": farm_id}


# ── Analysis routes ───────────────────────────────────────────────────────────

@app.get("/analyses/{farm_id}")
def get_analyses(farm_id: str, user_id: str = Depends(get_current_user)):
    import json
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM analyses WHERE farm_id=? ORDER BY timestamp DESC LIMIT 10", (farm_id,)
    ).fetchall()
    conn.close()
    return [{ **dict(r), "soil": json.loads(r["soil"] or "{}"),
              "carbon": json.loads(r["carbon"] or "{}"),
              "recommendations": json.loads(r["recommendations"] or "[]") } for r in rows]


@app.post("/sensor/reading")
def sensor_reading(req: SensorReadingRequest, user_id: str = Depends(get_current_user)):
    import uuid, json
    calc = CarbonCalculator()
    ph_score       = 1.0 - abs(req.ph - 6.5) / 3.5
    n_score        = min(1.0, req.n / 80.0)
    moisture_score = min(1.0, req.moisture / 40.0)
    ndvi_proxy     = round((ph_score * 0.3 + n_score * 0.4 + moisture_score * 0.3) * 0.85, 3)
    health_score   = round(min(100.0, ndvi_proxy * 120), 1)
    carbon         = calc.calculate_carbon(ndvi_proxy, "default")

    def _flag(val, low, high):
        if val < low:  return "LOW"
        if val > high: return "HIGH"
        return "OK"

    soil_status = {
        "n":           {"value": req.n,           "status": _flag(req.n, 40, 80)},
        "p":           {"value": req.p,           "status": _flag(req.p, 20, 40)},
        "k":           {"value": req.k,           "status": _flag(req.k, 100, 200)},
        "ph":          {"value": req.ph,          "status": _flag(req.ph, 6.0, 7.5)},
        "ec":          {"value": req.ec,          "status": _flag(req.ec, 0.5, 2.0)},
        "moisture":    {"value": req.moisture,    "status": _flag(req.moisture, 20, 50)},
        "temperature": {"value": req.temperature, "status": _flag(req.temperature, 15, 35)},
    }
    recommendations = _sensor_recommendations(req, ndvi_proxy)
    analysis_id = str(uuid.uuid4())
    soil = {"n": req.n, "p": req.p, "k": req.k, "ph": req.ph,
            "ec": req.ec, "moisture": req.moisture, "temperature": req.temperature}
    carbon_doc = {"biomass": carbon["biomass"], "totalCarbon": carbon["carbon"],
                  "co2Equivalent": carbon["co2_equivalent"]}
    conn = get_db()
    conn.execute(
        "INSERT INTO analyses (id, farm_id, farmer_id, timestamp, source, ndvi, health_score, soil, carbon, recommendations) VALUES (?,?,?,?,?,?,?,?,?,?)",
        (analysis_id, req.farm_id, user_id, req.timestamp or datetime.datetime.utcnow().isoformat(),
         req.source, ndvi_proxy, health_score, json.dumps(soil), json.dumps(carbon_doc), json.dumps(recommendations))
    )
    conn.commit()
    conn.close()
    return {"analysis_id": analysis_id, "health_score": health_score,
            "ndvi_proxy": ndvi_proxy, "soil_status": soil_status,
            "carbon": carbon, "recommendations": recommendations}


@app.get("/sensor/latest/{farm_id}")
def sensor_latest(farm_id: str, user_id: str = Depends(get_current_user)):
    import json
    conn = get_db()
    row = conn.execute(
        "SELECT * FROM analyses WHERE farm_id=? AND source='hardware' ORDER BY timestamp DESC LIMIT 1",
        (farm_id,)
    ).fetchone()
    conn.close()
    if not row:
        return {"error": "No readings found"}
    return {**dict(row), "soil": json.loads(row["soil"] or "{}"),
            "carbon": json.loads(row["carbon"] or "{}"),
            "recommendations": json.loads(row["recommendations"] or "[]")}


@app.post("/analyse")
def analyse(req: AnalyseRequest, user_id: str = Depends(get_current_user)):
    import uuid, json
    if not _EE_AVAILABLE:
        raise HTTPException(status_code=503, detail="Earth Engine not available")
    try:
        result = get_ndvi_for_farm(req.boundary, req.start_date, req.end_date)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    ndvi         = result["ndvi"]
    health_score = round(min(100.0, ndvi * 100 * 1.2), 1)
    carbon       = CarbonCalculator().calculate_carbon(ndvi, req.crop_type or "default")
    analysis_id  = str(uuid.uuid4())
    carbon_doc   = {"biomass": carbon["biomass"], "totalCarbon": carbon["carbon"],
                    "co2Equivalent": carbon["co2_equivalent"]}
    recs = _recommendations(ndvi)
    conn = get_db()
    conn.execute(
        "INSERT INTO analyses (id, farm_id, farmer_id, crop_type, growth_stage, ndvi, health_score, carbon, recommendations) VALUES (?,?,?,?,?,?,?,?,?)",
        (analysis_id, req.farm_id, user_id, req.crop_type, req.growth_stage,
         ndvi, health_score, json.dumps(carbon_doc), json.dumps(recs))
    )
    conn.commit()
    conn.close()
    return {"analysis_id": analysis_id, "ndvi": ndvi, "healthScore": health_score, "carbon": carbon}


@app.post("/climate-risks")
def climate_risks(req: ClimateRequest, user_id: str = Depends(get_current_user)):
    import uuid, json
    if not _EE_AVAILABLE:
        raise HTTPException(status_code=503, detail="Earth Engine not available")
    try:
        risks = get_climate_risks(req.boundary, req.days_back)
    except Exception as e:
        raise HTTPException(status_code=422, detail=str(e))
    conn = get_db()
    alerts = []
    _SEVERITY = lambda r: "high" if r > 70 else "medium" if r > 40 else "low"
    for alert_type, key, rec in [
        ("drought", "drought_risk",     "Consider irrigation scheduling."),
        ("heat",    "heat_stress_risk", "Provide shade nets and increase irrigation."),
        ("flood",   "flood_risk",       "Ensure drainage channels are clear."),
    ]:
        score = risks[key]
        if score > 20:
            alert_id = str(uuid.uuid4())
            conn.execute(
                "INSERT INTO climate_alerts (id, farm_id, type, severity, risk_percentage, recommendation) VALUES (?,?,?,?,?,?)",
                (alert_id, req.farm_id, alert_type, _SEVERITY(score), score, rec)
            )
            alerts.append({"type": alert_type, "severity": _SEVERITY(score),
                           "risk_percentage": score, "recommendation": rec})
    conn.commit()
    conn.close()
    return {"farm_id": req.farm_id, "risks": risks, "alerts_created": len(alerts)}


@app.get("/climate-alerts/{farm_id}")
def get_climate_alerts(farm_id: str, user_id: str = Depends(get_current_user)):
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM climate_alerts WHERE farm_id=? ORDER BY created_at DESC LIMIT 5", (farm_id,)
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


@app.get("/carbon-credits")
def get_carbon_credits(user_id: str = Depends(get_current_user)):
    conn = get_db()
    rows = conn.execute("SELECT * FROM carbon_credits WHERE farmer_id=?", (user_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


@app.get("/payments")
def get_payments(user_id: str = Depends(get_current_user)):
    conn = get_db()
    rows = conn.execute(
        "SELECT * FROM payments WHERE farmer_id=? ORDER BY created_at DESC", (user_id,)
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


@app.post("/simulate")
def simulate(req: SimulateRequest, user_id: str = Depends(get_current_user)):
    import uuid, json
    sim  = SensorSimulator(seed=req.seed)
    calc = CarbonCalculator()

    def _build_and_save(reading: dict) -> dict:
        carbon = calc.calculate_carbon(reading["ndvi"], reading["crop_type"])
        analysis_id = str(uuid.uuid4())
        soil   = reading["soil"]
        carbon_doc = {"biomass": carbon["biomass"], "totalCarbon": carbon["carbon"],
                      "co2Equivalent": carbon["co2_equivalent"]}
        recs = _recommendations(reading["ndvi"])
        conn = get_db()
        conn.execute(
            "INSERT INTO analyses (id, farm_id, farmer_id, crop_type, growth_stage, gpr, health_score, ndvi, soil, carbon, recommendations, simulated) VALUES (?,?,?,?,?,?,?,?,?,?,?,1)",
            (analysis_id, req.farm_id, user_id, reading["crop_type"], reading["growth_stage"],
             reading["gpr"], reading["health_score"], reading["ndvi"],
             json.dumps(soil), json.dumps(carbon_doc), json.dumps(recs))
        )
        conn.commit()
        conn.close()
        return {"analysis_id": analysis_id, **reading, "carbon": carbon_doc}

    if req.days > 0:
        readings = sim.generate_history(req.farm_id, days=req.days,
                                        crop_type=req.crop_type or None,
                                        soil_type=req.soil_type or None)
        saved = [_build_and_save(r) for r in readings]
        return {"farm_id": req.farm_id, "count": len(saved), "analyses": saved}
    reading = sim.generate_reading(req.farm_id, req.crop_type or None, req.soil_type or None)
    return _build_and_save(reading)


@app.post("/fertilizer")
def fertilizer(req: FertilizerRequest, user_id: str = Depends(get_current_user)):
    result = CarbonCalculator().calculate_fertilizer(
        soil_data=req.soil, crop_type=req.crop_type,
        target_yield=req.target_yield, area_ha=req.area_ha,
    )
    return {"farm_id": req.farm_id, **result}


@app.get("/simulate/analysis")
def simulate_analysis(crop_type: str = "", soil_type: str = "", seed: int | None = None):
    sim  = SensorSimulator(seed=seed)
    calc = CarbonCalculator()
    soil = sim.generate_soil_data(soil_type or None)
    crop = sim.generate_crop_data(crop_type or None)
    carbon = calc.calculate_carbon(crop["ndvi"], crop["crop_type"])
    return {"soil": {k: soil[k] for k in ("n","p","k","ph","ec","moisture","temperature")},
            "crop": crop, "carbon": carbon, "timestamp": soil["timestamp"]}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _recommendations(ndvi: float) -> list[str]:
    if ndvi < 0.2: return ["Crop stress detected — check water and nutrient levels.",
                            "Consider soil testing for N/P/K deficiency."]
    if ndvi < 0.4: return ["Moderate vegetation — apply top-dressing fertilizer.",
                            "Monitor for pest or disease outbreak."]
    if ndvi < 0.6: return ["Good crop health. Maintain current irrigation schedule."]
    return ["Excellent vegetation density. Farm is sequestering carbon effectively."]


def _sensor_recommendations(req: SensorReadingRequest, ndvi: float) -> list[str]:
    tips = []
    if req.n < 40:    tips.append(f"Nitrogen LOW ({req.n} ppm) — apply Urea or compost.")
    elif req.n > 80:  tips.append(f"Nitrogen HIGH ({req.n} ppm) — skip N fertilizer this cycle.")
    if req.p < 20:    tips.append(f"Phosphorus LOW ({req.p} ppm) — apply DAP or SSP.")
    if req.k < 100:   tips.append(f"Potassium LOW ({req.k} ppm) — apply MOP.")
    if req.ph < 6.0:  tips.append(f"pH too acidic ({req.ph}) — apply agricultural lime.")
    elif req.ph > 7.5:tips.append(f"pH alkaline ({req.ph}) — apply gypsum or sulfur.")
    if req.ec > 2.0:  tips.append(f"EC high ({req.ec} mS/cm) — risk of salt stress, flush soil.")
    if req.moisture < 20:  tips.append(f"Moisture LOW ({req.moisture}%) — irrigate soon.")
    elif req.moisture > 50:tips.append(f"Moisture HIGH ({req.moisture}%) — check drainage.")
    if req.temperature > 35: tips.append(f"Soil temperature HIGH ({req.temperature}°C) — mulch to cool.")
    if not tips: tips.append("All soil parameters are within optimal range. 🌱")
    return tips
