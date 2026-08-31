import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

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
  final String source;
  final double lat;
  final double lng;
  final String placeName;

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
    this.lat = 0,
    this.lng = 0,
    this.placeName = '',
  });

  // Biomass = 3.05 × NDVI − 0.35
  static double calcBiomass(double ndvi) => (3.05 * ndvi - 0.35).clamp(0.0, 100.0);

  // Carbon = Biomass × 0.45
  static double calcCarbon(double biomass) => biomass * 0.45;

  // CO₂e = Carbon × 3.67
  static double calcCo2e(double carbon) => carbon * 3.67;

  // Health score mapped from NDVI (0–1) to 0–100
  static double calcHealthScore(double ndvi) => (ndvi * 100).clamp(0.0, 100.0);

  // Carbon credits = delta CO₂e sequestered above baseline
  static double calcCredits(double carbon, [double baseline = 0.0]) =>
      (calcCo2e(carbon) - calcCo2e(baseline)).clamp(0.0, double.infinity);

  // Farmer keeps 90% at ₹2,100/ton
  static double calcFarmerPayment(double credits) => credits * 2100 * 0.90;

  Map<String, dynamic> toJson() => {
        'ndvi': ndvi, 'biomass': biomass, 'carbon': carbon,
        'co2e': co2e, 'healthScore': healthScore,
        'carbonCredits': carbonCredits, 'farmerPayment': farmerPayment,
        'satelliteDate': satelliteDate.toIso8601String(),
        'source': source, 'lat': lat, 'lng': lng, 'placeName': placeName,
      };

  factory SatelliteResult.fromJson(Map<String, dynamic> j, String src) {
    final ndvi    = (j['ndvi'] as num).toDouble();
    final biomass = (j['biomass'] as num?)?.toDouble() ?? calcBiomass(ndvi);
    final carbon  = (j['carbon'] as num?)?.toDouble()  ?? calcCarbon(biomass);
    final co2e    = (j['co2e'] as num?)?.toDouble()    ?? calcCo2e(carbon);
    return SatelliteResult(
      ndvi: ndvi, biomass: biomass, carbon: carbon, co2e: co2e,
      healthScore:    (j['healthScore']    as num?)?.toDouble() ?? calcHealthScore(ndvi),
      carbonCredits:  (j['carbonCredits']  as num?)?.toDouble() ?? 0,
      farmerPayment:  (j['farmerPayment']  as num?)?.toDouble() ?? 0,
      satelliteDate:  DateTime.parse(j['satelliteDate'] as String),
      source: src,
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0,
      placeName: j['placeName'] as String? ?? '',
    );
  }

  SatelliteResult copyWith({DateTime? satelliteDate, String? source}) => SatelliteResult(
    ndvi: ndvi, biomass: biomass, carbon: carbon, co2e: co2e,
    healthScore: healthScore, carbonCredits: carbonCredits, farmerPayment: farmerPayment,
    satelliteDate: satelliteDate ?? this.satelliteDate,
    source: source ?? this.source, lat: lat, lng: lng, placeName: placeName,
  );

  static SatelliteResult mock() {
    const ndvi = 0.68;
    final biomass = calcBiomass(ndvi);
    final carbon = calcCarbon(biomass);
    final co2e = calcCo2e(carbon);
    final credits = calcCredits(carbon);
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

  /// Reverse geocode lat/lng → "Village, District, State" using OSM Nominatim
  static Future<String> geocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&zoom=14',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'CarbonTechApp/1.0'}
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final a = j['address'] as Map<String, dynamic>? ?? {};
        final parts = [
          a['village'] ?? a['town'] ?? a['suburb'] ?? a['neighbourhood'] ?? a['hamlet'],
          a['county']  ?? a['state_district'] ?? a['district'],
          a['state'],
        ].whereType<String>().toList();
        if (parts.isNotEmpty) return parts.join(', ');
        return j['display_name']?.toString().split(',').take(3).join(',').trim() ?? '';
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  /// Fetch NDVI from the Cloud Function, compute all derived values.
  /// Falls back to cache, then to mock data.
  Future<SatelliteResult> fetchNDVI({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String startDate,
    required String endDate,
    double baselineCarbon = 0.0,
    double? sensorNdvi,
  }) async {
    // Always geocode first — independent of data source
    final place = await geocode(lat, lng);

    SatelliteResult build(Map<String, dynamic> data, String src) {
      final ndvi    = (data['ndvi']    as num).toDouble();
      final biomass = (data['biomass'] as num?)?.toDouble() ?? SatelliteResult.calcBiomass(ndvi);
      final carbon  = (data['carbon']  as num?)?.toDouble() ?? SatelliteResult.calcCarbon(biomass);
      final co2e    = (data['co2e']    as num?)?.toDouble() ?? SatelliteResult.calcCo2e(carbon);
      final credits = (data['carbon_credits'] as num?)?.toDouble() ?? SatelliteResult.calcCredits(carbon, baselineCarbon);
      final payment = (data['farmer_payment'] as num?)?.toDouble() ?? SatelliteResult.calcFarmerPayment(credits);
      final dateStr = data['date'] as String? ?? DateTime.now().toIso8601String();
      return SatelliteResult(
        ndvi: ndvi, biomass: biomass, carbon: carbon, co2e: co2e,
        healthScore:   SatelliteResult.calcHealthScore(ndvi),
        carbonCredits: credits, farmerPayment: payment,
        satelliteDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
        source: src, lat: lat, lng: lng, placeName: place,
      );
    }

    // 1. Backend /ndvi — uses Open-Meteo real weather data per location
    try {
      final uri = Uri.parse('$kApiBase/ndvi').replace(queryParameters: {
        'lat': lat.toString(), 'lng': lng.toString(),
        'start_date': startDate, 'end_date': endDate,
      });
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data   = jsonDecode(res.body) as Map<String, dynamic>;
        final src    = data['source'] as String? ?? 'backend';
        final result = build(data, src);
        await _cache(result);
        return result;
      }
    } catch (_) {}

    // 2. Cached result (not mock)
    final cached = await _loadCache();
    if (cached != null && cached.source != 'mock') {
      // update location to current pin
      final updated = SatelliteResult(
        ndvi: cached.ndvi, biomass: cached.biomass, carbon: cached.carbon,
        co2e: cached.co2e, healthScore: cached.healthScore,
        carbonCredits: cached.carbonCredits, farmerPayment: cached.farmerPayment,
        satelliteDate: cached.satelliteDate, source: 'cache',
        lat: lat, lng: lng, placeName: place,
      );
      await _cache(updated);
      return updated;
    }

    // 3. Sensor ndvi as last resort
    if (sensorNdvi != null && sensorNdvi > 0) {
      final biomass = SatelliteResult.calcBiomass(sensorNdvi);
      final carbon  = SatelliteResult.calcCarbon(biomass);
      final co2e    = SatelliteResult.calcCo2e(carbon);
      final credits = SatelliteResult.calcCredits(carbon, baselineCarbon);
      final result  = SatelliteResult(
        ndvi: sensorNdvi, biomass: biomass, carbon: carbon, co2e: co2e,
        healthScore:   SatelliteResult.calcHealthScore(sensorNdvi),
        carbonCredits: credits, farmerPayment: SatelliteResult.calcFarmerPayment(credits),
        satelliteDate: DateTime.now(), source: 'sensor',
        lat: lat, lng: lng, placeName: place,
      );
      await _cache(result);
      return result;
    }

    // 4. Absolute fallback — estimated with real location
    final result = SatelliteResult(
      ndvi: 0.5, biomass: SatelliteResult.calcBiomass(0.5),
      carbon: SatelliteResult.calcCarbon(SatelliteResult.calcBiomass(0.5)),
      co2e: SatelliteResult.calcCo2e(SatelliteResult.calcCarbon(SatelliteResult.calcBiomass(0.5))),
      healthScore: 50, carbonCredits: 0, farmerPayment: 0,
      satelliteDate: DateTime.now(), source: 'estimated',
      lat: lat, lng: lng, placeName: place,
    );
    await _cache(result);
    return result;
  }

  Future<SatelliteResult?> loadCache() => _loadCache();

  Future<void> _cache(SatelliteResult r) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = r.toJson();
    payload['cachedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  Future<SatelliteResult?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final json  = jsonDecode(raw) as Map<String, dynamic>;
      // No TTL — always return last scan so carbon report stays accurate
      return SatelliteResult.fromJson(json, 'cache');
    } catch (_) {
      return null;
    }
  }
}
