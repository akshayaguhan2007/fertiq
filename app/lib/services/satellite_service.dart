import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Cloud Functions base URL — replace with your project's URL after deploy
const String kFunctionsBase =
    'https://us-central1-carbon-tech-67a3d.cloudfunctions.net';

class SatelliteResult {
  final double ndvi;
  final double biomass;
  final double carbon;
  final double co2e;
  final double healthScore;
  final double carbonCredits;
  final double farmerPayment;
  final DateTime satelliteDate;
  final String source; // 'satellite' | 'cache' | 'mock'

  const SatelliteResult({
    required this.ndvi,
    required this.biomass,
    required this.carbon,
    required this.co2e,
    required this.healthScore,
    required this.carbonCredits,
    required this.farmerPayment,
    required this.satelliteDate,
    required this.source,
  });

  // Biomass = 3.05 × NDVI − 0.35
  static double calcBiomass(double ndvi) => (3.05 * ndvi - 0.35).clamp(0.0, 100.0);

  // Carbon = Biomass × 0.45
  static double calcCarbon(double biomass) => biomass * 0.45;

  // CO₂e = Carbon × 3.67
  static double calcCo2e(double carbon) => carbon * 3.67;

  // Health score mapped from NDVI (0–1) to 0–100
  static double calcHealthScore(double ndvi) => (ndvi * 100).clamp(0.0, 100.0);

  // Carbon credits = (current carbon − baseline) × 3.67
  static double calcCredits(double carbon, double baseline) =>
      ((carbon - baseline) * 3.67).clamp(0.0, double.infinity);

  // Farmer keeps 90% at ₹2,100/ton
  static double calcFarmerPayment(double credits) => credits * 2100 * 0.90;

  Map<String, dynamic> toJson() => {
        'ndvi': ndvi,
        'biomass': biomass,
        'carbon': carbon,
        'co2e': co2e,
        'healthScore': healthScore,
        'carbonCredits': carbonCredits,
        'farmerPayment': farmerPayment,
        'satelliteDate': satelliteDate.toIso8601String(),
        'source': source,
      };

  factory SatelliteResult.fromJson(Map<String, dynamic> j, String src) {
    final ndvi = (j['ndvi'] as num).toDouble();
    final biomass = (j['biomass'] as num?)?.toDouble() ?? calcBiomass(ndvi);
    final carbon = (j['carbon'] as num?)?.toDouble() ?? calcCarbon(biomass);
    final co2e = (j['co2e'] as num?)?.toDouble() ?? calcCo2e(carbon);
    return SatelliteResult(
      ndvi: ndvi,
      biomass: biomass,
      carbon: carbon,
      co2e: co2e,
      healthScore: (j['healthScore'] as num?)?.toDouble() ?? calcHealthScore(ndvi),
      carbonCredits: (j['carbonCredits'] as num?)?.toDouble() ?? 0,
      farmerPayment: (j['farmerPayment'] as num?)?.toDouble() ?? 0,
      satelliteDate: DateTime.parse(j['satelliteDate'] as String),
      source: src,
    );
  }

  static SatelliteResult mock() {
    const ndvi = 0.68;
    final biomass = calcBiomass(ndvi);
    final carbon = calcCarbon(biomass);
    final co2e = calcCo2e(carbon);
    final credits = calcCredits(carbon, 45.0);
    return SatelliteResult(
      ndvi: ndvi,
      biomass: biomass,
      carbon: carbon,
      co2e: co2e,
      healthScore: calcHealthScore(ndvi),
      carbonCredits: credits,
      farmerPayment: calcFarmerPayment(credits),
      satelliteDate: DateTime.now().subtract(const Duration(days: 3)),
      source: 'mock',
    );
  }
}

class SatelliteService {
  static const _cacheKey = 'satellite_result_cache';
  static const _cacheTtlHours = 24;

  /// Fetch NDVI from the Cloud Function, compute all derived values.
  /// Falls back to cache, then to mock data.
  Future<SatelliteResult> fetchNDVI({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String startDate,
    required String endDate,
    double baselineCarbon = 45.0,
  }) async {
    try {
      final uri = Uri.parse('$kFunctionsBase/getNDVI').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radiusMeters.toString(),
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ndvi = (data['ndvi'] as num).toDouble();
        final biomass = SatelliteResult.calcBiomass(ndvi);
        final carbon = SatelliteResult.calcCarbon(biomass);
        final co2e = SatelliteResult.calcCo2e(carbon);
        final credits = SatelliteResult.calcCredits(carbon, baselineCarbon);

        final result = SatelliteResult(
          ndvi: ndvi,
          biomass: biomass,
          carbon: carbon,
          co2e: co2e,
          healthScore: SatelliteResult.calcHealthScore(ndvi),
          carbonCredits: credits,
          farmerPayment: SatelliteResult.calcFarmerPayment(credits),
          satelliteDate: DateTime.parse(
              data['date'] as String? ?? DateTime.now().toIso8601String()),
          source: 'satellite',
        );

        await _cache(result);
        return result;
      }
    } catch (_) {}

    // Try cache
    final cached = await _loadCache();
    if (cached != null) return cached;

    // Final fallback
    return SatelliteResult.mock();
  }

  Future<void> _cache(SatelliteResult r) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = r.toJson();
    payload['cachedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  Future<SatelliteResult?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt).inHours > _cacheTtlHours) return null;
      return SatelliteResult.fromJson(json, 'cache');
    } catch (_) {
      return null;
    }
  }
}
