from __future__ import annotations
import ee
import json
import os


def initialize_earth_engine():
    """Initialize Earth Engine using a service account (for server environments)."""
    sa_key = os.getenv("GEE_SERVICE_ACCOUNT_KEY")
    project = os.getenv("GOOGLE_EARTH_ENGINE_PROJECT")

    if sa_key:
        credentials = ee.ServiceAccountCredentials(
            email=None, key_data=sa_key
        )
        ee.Initialize(credentials, project=project)
    else:
        # Falls back to `gcloud auth` for local development
        ee.Initialize(project=project)


def get_ndvi_for_farm(
    farm_boundary: str | dict,
    start_date: str,
    end_date: str,
) -> dict:
    """
    Compute median NDVI, biomass and carbon sequestration for a farm boundary.

    Args:
        farm_boundary: GeoJSON polygon (str or dict)
        start_date:    'YYYY-MM-DD'
        end_date:      'YYYY-MM-DD'

    Returns:
        {
            'ndvi':          float  (0–1),
            'biomass':       float  (tons/ha),
            'carbon':        float  (tons C/ha),
            'co2_equivalent': float (tons CO2e/ha),
        }

    Raises:
        ValueError: if no cloud-free imagery is available for the period.
    """
    if isinstance(farm_boundary, str):
        farm_boundary = json.loads(farm_boundary)

    boundary = ee.Geometry.Polygon(farm_boundary["coordinates"])

    collection = (
        ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED")
        .filterBounds(boundary)
        .filterDate(start_date, end_date)
        .filter(ee.Filter.lt("CLOUDY_PIXEL_PERCENTAGE", 20))
    )

    if collection.size().getInfo() == 0:
        raise ValueError(
            f"No cloud-free Sentinel-2 imagery between {start_date} and {end_date}"
        )

    def _add_ndvi(image):
        return image.addBands(
            image.normalizedDifference(["B8", "B4"]).rename("NDVI")
        )

    median_ndvi = (
        collection.map(_add_ndvi)
        .select("NDVI")
        .median()
        .clip(boundary)
    )

    stats = median_ndvi.reduceRegion(
        reducer=ee.Reducer.mean(),
        geometry=boundary,
        scale=10,
        maxPixels=1e9,
    )

    ndvi: float = stats.get("NDVI").getInfo()

    if ndvi is None:
        raise ValueError("NDVI computation returned null — check farm boundary.")

    # Biomass via Dong et al. linear approximation (general cropland)
    biomass = max(0.0, 3.05 * ndvi - 0.35)
    carbon = biomass * 0.47          # IPCC carbon fraction for crops
    co2_equivalent = carbon * 3.667  # C → CO2 molecular weight ratio

    return {
        "ndvi": round(ndvi, 4),
        "biomass": round(biomass, 3),
        "carbon": round(carbon, 3),
        "co2_equivalent": round(co2_equivalent, 3),
    }


def get_climate_risks(
    farm_boundary: str | dict,
    days_back: int = 30,
) -> dict:
    """
    Estimate drought, heat-stress and flood risk using ERA5 reanalysis.

    Returns:
        {
            'drought_risk':     float (0–100),
            'heat_stress_risk': float (0–100),
            'flood_risk':       float (0–100),
        }
    """
    import datetime

    if isinstance(farm_boundary, str):
        farm_boundary = json.loads(farm_boundary)

    boundary = ee.Geometry.Polygon(farm_boundary["coordinates"])
    end = datetime.date.today()
    start = end - datetime.timedelta(days=days_back)

    era5 = (
        ee.ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")
        .filterBounds(boundary)
        .filterDate(str(start), str(end))
        .select([
            "total_precipitation_sum",
            "temperature_2m_max",
            "temperature_2m_min",
        ])
    )

    def _region_mean(image):
        return image.reduceRegion(
            reducer=ee.Reducer.mean(),
            geometry=boundary,
            scale=11132,
            maxPixels=1e6,
        )

    means = era5.mean()
    stats = means.reduceRegion(
        reducer=ee.Reducer.mean(),
        geometry=boundary,
        scale=11132,
        maxPixels=1e6,
    ).getInfo()

    precip_mm = (stats.get("total_precipitation_sum") or 0) * 1000  # m → mm
    temp_max_c = (stats.get("temperature_2m_max") or 273.15) - 273.15

    # Simple heuristic risk scoring (0–100)
    drought_risk = max(0.0, min(100.0, (1 - precip_mm / 5.0) * 100))
    heat_stress  = max(0.0, min(100.0, (temp_max_c - 30) / 15 * 100))
    flood_risk   = max(0.0, min(100.0, (precip_mm - 10) / 10 * 100))

    return {
        "drought_risk":     round(drought_risk, 1),
        "heat_stress_risk": round(heat_stress, 1),
        "flood_risk":       round(flood_risk, 1),
    }
