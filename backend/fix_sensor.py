c = open('main.py', 'r', encoding='utf-8').read()
start = c.find('@app.get("/sensor/live")')
end   = c.find('def _sensor_recommendations')

new = '''@app.get("/sensor/live")
def sensor_live(user_id: str = Depends(get_current_user)):
    try:
        from pymongo import MongoClient as _MC
        _cli = _MC("mongodb+srv://teamoraclesece_db_user:fYmBEjK1Lv9pyF8s@agrivision.ern2zcu.mongodb.net/?appName=AgriVision", serverSelectionTimeoutMS=5000)
        _row = _cli["CropHealth"]["sensor_data"].find_one({"nitrogen": {"$exists": True}}, sort=[("timestamp", -1)])
        _cli.close()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"DB error: {e}")
    if not _row:
        raise HTTPException(status_code=404, detail="No sensor data yet")
    n           = float(_row.get("nitrogen",    0))
    p           = float(_row.get("phosphorus",  0))
    k           = float(_row.get("potassium",   0))
    ph          = float(_row.get("ph",          7.0))
    ec          = float(_row.get("ec",          0)) / 1000.0
    moisture    = float(_row.get("moisture",    0))
    temperature = float(_row.get("temperature", 25))
    calc = CarbonCalculator()
    ph_score       = 1.0 - abs(ph - 6.5) / 3.5
    n_score        = min(1.0, n / 80.0)
    moisture_score = min(1.0, moisture / 40.0)
    ndvi_proxy   = round((ph_score * 0.3 + n_score * 0.4 + moisture_score * 0.3) * 0.85, 3)
    health_score = round(min(100.0, ndvi_proxy * 120), 1)
    carbon       = calc.calculate_carbon(ndvi_proxy, "default")
    ts     = _row.get("timestamp")
    ts_str = ts.isoformat() if hasattr(ts, "isoformat") else str(ts)
    return {
        "n": n, "p": p, "k": k, "ph": ph, "ec": ec,
        "moisture": moisture, "temperature": temperature,
        "health_score": health_score, "ndvi_proxy": ndvi_proxy,
        "carbon": carbon["carbon"], "co2_equivalent": carbon["co2_equivalent"],
        "recommendations": [], "source": "hardware", "timestamp": ts_str,
    }


'''

result = c[:start] + new + c[end:]
open('main.py', 'w', encoding='utf-8').write(result)
print('MongoClient present:', 'MongoClient' in result)
print('psycopg2.connect present:', 'psycopg2.connect' in result)
