class CarbonCalculator:
    # Crop-specific biomass regression coefficients (a·NDVI + b) and IPCC carbon fractions
    _CROP_FACTORS: dict[str, dict] = {
        "rice":     {"a": 3.2,  "b": -0.4,  "carbon_fraction": 0.42},
        "wheat":    {"a": 2.8,  "b": -0.3,  "carbon_fraction": 0.44},
        "maize":    {"a": 3.5,  "b": -0.5,  "carbon_fraction": 0.46},
        "soybean":  {"a": 2.4,  "b": -0.2,  "carbon_fraction": 0.43},
        "default":  {"a": 3.05, "b": -0.35, "carbon_fraction": 0.45},
    }

    # N-P-K crop removal rates (kg per ton of yield)
    _NPK_REMOVAL: dict[str, dict] = {
        "rice":    {"n": 16, "p": 8,  "k": 14},
        "wheat":   {"n": 22, "p": 10, "k": 18},
        "maize":   {"n": 20, "p": 8,  "k": 16},
        "soybean": {"n": 60, "p": 12, "k": 25},
    }
    _NPK_DEFAULT = {"n": 16, "p": 8, "k": 14}

    # Fertiliser prices (₹/kg) — update as market changes
    _PRICES = {"urea": 6, "dap": 27, "mop": 17}

    def calculate_carbon(self, ndvi: float, crop_type: str = "default") -> dict:
        """
        Calculate carbon sequestration metrics from NDVI.

        Args:
            ndvi:      float 0–1 from satellite analysis
            crop_type: key in _CROP_FACTORS (falls back to 'default')

        Returns:
            biomass       tons/ha aboveground dry matter
            carbon        tons C/ha
            co2_equivalent tons CO2e/ha  (C × 44/12 = 3.667)
            carbon_credits eligible credits (1 credit = 1 ton CO2e, min 0)
        """
        f = self._CROP_FACTORS.get(crop_type.lower(), self._CROP_FACTORS["default"])
        biomass        = max(0.0, f["a"] * ndvi + f["b"])
        carbon         = biomass * f["carbon_fraction"]
        co2_equivalent = carbon * 3.667          # IPCC: C × (44/12)
        carbon_credits = round(max(0.0, co2_equivalent), 2)  # floor at 0

        return {
            "biomass":        round(biomass, 3),
            "carbon":         round(carbon, 3),
            "co2_equivalent": round(co2_equivalent, 3),
            "carbon_credits": carbon_credits,
        }

    def calculate_fertilizer(
        self,
        soil_data: dict,
        crop_type: str,
        target_yield: float,
        area_ha: float = 1.0,
    ) -> dict:
        """
        Calculate fertilizer recommendations for a given crop and target yield.

        Args:
            soil_data:    {'n': ppm, 'p': ppm, 'k': ppm}
            crop_type:    crop name (rice / wheat / maize / soybean)
            target_yield: tons/ha
            area_ha:      farm area — scales total bag counts

        Returns:
            nutrient demands, deficits, fertiliser kg/ha and total cost estimate (₹)
        """
        removal = self._NPK_REMOVAL.get(crop_type.lower(), self._NPK_DEFAULT)

        # Total nutrient demand (kg/ha)
        n_demand = target_yield * removal["n"]
        p_demand = target_yield * removal["p"]
        k_demand = target_yield * removal["k"]

        # Available soil nutrient (ppm × 2 ≈ kg/ha for 0–20 cm depth, bulk density ~1)
        n_supply = soil_data.get("n", 0) * 2
        p_supply = soil_data.get("p", 0) * 2
        k_supply = soil_data.get("k", 0) * 2

        n_deficit = max(0.0, n_demand - n_supply)
        p_deficit = max(0.0, p_demand - p_supply)
        k_deficit = max(0.0, k_demand - k_supply)

        # Fertiliser conversions (per ha)
        # Urea  → 46% N
        # DAP   → 18% N + 46% P₂O₅;  P₂O₅ contains 43.6% P  →  effective P = 46% × 43.6% ≈ 20%
        # MOP   → 60% K₂O;            K₂O  contains 83% K    →  effective K = 60% × 83%   ≈ 50%
        urea_kg = round(n_deficit / 0.46, 1)
        dap_kg  = round(p_deficit / 0.20, 1)   # corrected from original 0.46
        mop_kg  = round(k_deficit / 0.50, 1)   # corrected from original 0.60

        cost_per_ha = (
            urea_kg * self._PRICES["urea"]
            + dap_kg * self._PRICES["dap"]
            + mop_kg * self._PRICES["mop"]
        )

        return {
            "per_hectare": {
                "n_demand":  n_demand,  "p_demand":  p_demand,  "k_demand":  k_demand,
                "n_deficit": n_deficit, "p_deficit": p_deficit, "k_deficit": k_deficit,
                "urea_kg":   urea_kg,   "dap_kg":    dap_kg,    "mop_kg":    mop_kg,
            },
            "total": {
                "urea_kg": round(urea_kg * area_ha, 1),
                "dap_kg":  round(dap_kg  * area_ha, 1),
                "mop_kg":  round(mop_kg  * area_ha, 1),
            },
            "cost_estimate_inr": round(cost_per_ha * area_ha),
        }
