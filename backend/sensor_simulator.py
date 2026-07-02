from __future__ import annotations
import random
from datetime import datetime, timedelta


# Soil type baseline profiles: realistic agronomic ranges
_SOIL_PROFILES: dict[str, dict] = {
    "loamy": {"n": 60, "p": 25, "k": 120, "ph": 6.5, "ec": 1.2, "moisture": 30, "temperature": 26},
    "sandy": {"n": 30, "p": 15, "k":  80, "ph": 5.8, "ec": 0.6, "moisture": 15, "temperature": 28},
    "clay":  {"n": 80, "p": 35, "k": 160, "ph": 7.2, "ec": 1.8, "moisture": 40, "temperature": 24},
}

# Jitter ranges per parameter
_JITTER: dict[str, float] = {
    "n": 10, "p": 5, "k": 15, "ph": 0.3,
    "ec": 0.2, "moisture": 5, "temperature": 2,
}

# Clamp ranges: physically valid bounds
_BOUNDS: dict[str, tuple] = {
    "n": (0, 200), "p": (0, 100), "k": (0, 400),
    "ph": (4.0, 9.0), "ec": (0.1, 4.0),
    "moisture": (5, 60), "temperature": (10, 45),
}

SOIL_TYPES = list(_SOIL_PROFILES.keys())
CROP_TYPES = ["rice", "wheat", "maize", "soybean"]
GROWTH_STAGES = ["vegetative", "reproductive", "maturity"]


class SensorSimulator:
    def __init__(self, seed: int | None = None):
        """
        Args:
            seed: optional random seed for reproducible test data
        """
        self._rng = random.Random(seed)

    # ── Soil ─────────────────────────────────────────────────────────────────

    def generate_soil_data(self, soil_type: str | None = None) -> dict:
        """
        Generate realistic simulated soil sensor reading.

        Returns all 7 parameters plus a UTC ISO timestamp.
        """
        soil_type = soil_type or self._rng.choice(SOIL_TYPES)
        base = _SOIL_PROFILES[soil_type]

        data: dict = {"soil_type": soil_type}
        for key, base_val in base.items():
            jitter = self._rng.uniform(-_JITTER[key], _JITTER[key])
            lo, hi = _BOUNDS[key]
            data[key] = round(max(lo, min(hi, base_val + jitter)), 2)

        data["timestamp"] = datetime.utcnow().isoformat() + "Z"
        return data

    # ── Crop ─────────────────────────────────────────────────────────────────

    def generate_crop_data(
        self,
        crop_type: str | None = None,
        ndvi: float | None = None,
    ) -> dict:
        """
        Generate simulated crop health observation.

        GPR is clamped to [0, 1].
        health_score (0–100) is derived directly from NDVI, not raw GPR,
        so it stays meaningful regardless of the random GPR multiplier.
        """
        crop_type   = crop_type or self._rng.choice(CROP_TYPES)
        ndvi        = ndvi if ndvi is not None else round(self._rng.uniform(0.3, 0.8), 3)
        gpr         = round(min(1.0, max(0.0, ndvi * self._rng.uniform(0.7, 1.0))), 3)
        health_score = round(min(100.0, ndvi * 120), 1)  # NDVI 0.83+ → 100

        return {
            "crop_type":    crop_type,
            "ndvi":         ndvi,
            "gpr":          gpr,
            "health_score": health_score,
            "growth_stage": self._rng.choice(GROWTH_STAGES),
        }

    # ── Full reading ──────────────────────────────────────────────────────────

    def generate_reading(
        self,
        farm_id: str,
        crop_type: str | None = None,
        soil_type: str | None = None,
    ) -> dict:
        """
        Combine soil + crop into a single analysis-ready payload.
        Matches the Firestore `analyses` document schema.
        """
        soil = self.generate_soil_data(soil_type)
        crop = self.generate_crop_data(crop_type)

        return {
            "farm_id":     farm_id,
            "timestamp":   soil.pop("timestamp"),
            "crop_type":   crop["crop_type"],
            "growth_stage": crop["growth_stage"],
            "ndvi":        crop["ndvi"],
            "gpr":         crop["gpr"],
            "health_score": crop["health_score"],
            "soil": {k: soil[k] for k in ("n", "p", "k", "ph", "ec", "moisture", "temperature")},
        }

    # ── Historical batch ──────────────────────────────────────────────────────

    def generate_history(
        self,
        farm_id: str,
        days: int = 30,
        crop_type: str | None = None,
        soil_type: str | None = None,
    ) -> list[dict]:
        """
        Generate one reading per day for the past `days` days.
        NDVI follows a gentle sigmoid growth curve to simulate a crop season.

        Returns list ordered oldest → newest.
        """
        crop_type = crop_type or self._rng.choice(CROP_TYPES)
        soil_type = soil_type or self._rng.choice(SOIL_TYPES)
        now = datetime.utcnow()
        history = []

        for i in range(days):
            # Sigmoid NDVI growth: starts ~0.25, peaks ~0.75 at mid-season
            t = i / max(days - 1, 1)
            base_ndvi = 0.25 + 0.5 / (1 + pow(2.718, -10 * (t - 0.5)))
            ndvi = round(
                max(0.1, min(0.95, base_ndvi + self._rng.uniform(-0.03, 0.03))), 3
            )

            reading = self.generate_reading(farm_id, crop_type, soil_type)
            reading["ndvi"]        = ndvi
            reading["gpr"]         = round(min(1.0, ndvi * self._rng.uniform(0.7, 1.0)), 3)
            reading["health_score"] = round(min(100.0, ndvi * 120), 1)
            reading["timestamp"]   = (now - timedelta(days=days - 1 - i)).isoformat() + "Z"

            history.append(reading)

        return history
