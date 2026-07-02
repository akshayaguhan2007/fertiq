class GeoPoint {
  final double latitude, longitude;
  const GeoPoint(this.latitude, this.longitude);
}

class Farmer {
  final String id, name, phone, village, district, preferredLanguage;
  final double farmSize;
  final List<String> crops;
  final DateTime joinDate;

  const Farmer({
    required this.id, required this.name, required this.phone,
    required this.village, required this.district, required this.farmSize,
    required this.crops, required this.joinDate, required this.preferredLanguage,
  });
}

class Farm {
  final String id, farmerId, name, soilType;
  final GeoPoint location;
  final double area;
  final Map<String, dynamic> boundary;
  final List<String> crops;
  final DateTime createdAt;

  const Farm({
    required this.id, required this.farmerId, required this.name,
    required this.location, required this.area, required this.soilType,
    required this.boundary, required this.crops, required this.createdAt,
  });
}

class SoilReading {
  final double n, p, k, ph, ec, moisture, temperature;
  const SoilReading({
    required this.n, required this.p, required this.k,
    required this.ph, required this.ec,
    required this.moisture, required this.temperature,
  });
}

class CarbonReading {
  final double biomass, totalCarbon, co2Equivalent;
  const CarbonReading({
    required this.biomass, required this.totalCarbon, required this.co2Equivalent,
  });
}

class Analysis {
  final String id, farmId, cropType, growthStage;
  final DateTime timestamp;
  final double gpr, healthScore, ndvi;
  final SoilReading soil;
  final CarbonReading carbon;
  final List<String> recommendations;
  final String? imageUrl;

  const Analysis({
    required this.id, required this.farmId, required this.timestamp,
    required this.cropType, required this.growthStage, required this.gpr,
    required this.healthScore, required this.soil, required this.carbon,
    required this.ndvi, required this.recommendations, this.imageUrl,
  });
}

class CarbonCredit {
  final String id, farmerId, farmId, status;
  final double amount;
  final double? salePrice;
  final DateTime? soldDate;
  final String? paymentId;

  const CarbonCredit({
    required this.id, required this.farmerId, required this.farmId,
    required this.amount, required this.status,
    this.salePrice, this.soldDate, this.paymentId,
  });
}

class ClimateAlert {
  final String id, farmId, type, severity, recommendation;
  final double riskPercentage;
  final DateTime createdAt;

  const ClimateAlert({
    required this.id, required this.farmId, required this.type,
    required this.severity, required this.riskPercentage,
    required this.recommendation, required this.createdAt,
  });
}

class Payment {
  final String id, creditId, farmerId, farmId, paymentId, status;
  final double amount;
  final DateTime createdAt;

  const Payment({
    required this.id, required this.creditId, required this.farmerId,
    required this.farmId, required this.amount, required this.paymentId,
    required this.status, required this.createdAt,
  });
}
