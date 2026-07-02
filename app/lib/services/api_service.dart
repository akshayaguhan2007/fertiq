import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mock_data.dart';

/// Base URL of your FastAPI backend.
/// Change to your Pi's local IP when running on the same network,
/// e.g. 'http://192.168.1.50:8000'
const String kApiBase = 'http://localhost:8000';

class ApiService {
  final String _base;
  ApiService({String? base}) : _base = base ?? kApiBase;

  // ── Live sensor reading from Pi ─────────────────────────────────────────

  /// Called by Flutter after the Pi posts a reading.
  /// Fetches the latest hardware reading for [farmId] from the backend.
  Future<SensorResult?> fetchLatestReading(String farmId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/sensor/latest/$farmId'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data.containsKey('error')) return null;
        return SensorResult.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// POST a sensor payload directly (used for testing from Flutter).
  Future<SensorResult?> postSensorReading(Map<String, dynamic> payload) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/sensor/reading'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return SensorResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // ── Fertilizer recommendation ────────────────────────────────────────────

  Future<Map<String, dynamic>> getFertilizerRecommendation({
    required String farmId,
    required Map<String, double> soil,
    required String cropType,
    required double targetYield,
    required double areaHa,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/fertilizer'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'farm_id': farmId, 'soil': soil,
              'crop_type': cropType, 'target_yield': targetYield, 'area_ha': areaHa,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }

  // ── Simulate (fallback when no hardware) ────────────────────────────────

  Future<SensorResult> simulateFallback() async {
    final a = MockData.analysis;
    return SensorResult(
      healthScore: a.healthScore,
      ndviProxy: a.ndvi,
      n: a.soil.n, p: a.soil.p, k: a.soil.k,
      ph: a.soil.ph, ec: a.soil.ec,
      moisture: a.soil.moisture, temperature: a.soil.temperature,
      carbon: a.carbon.totalCarbon,
      co2Equivalent: a.carbon.co2Equivalent,
      recommendations: a.recommendations,
      soilStatus: {},
      source: 'mock',
    );
  }
}

// ── Result model ─────────────────────────────────────────────────────────────

class SensorResult {
  final double healthScore, ndviProxy;
  final double n, p, k, ph, ec, moisture, temperature;
  final double carbon, co2Equivalent;
  final List<String> recommendations;
  final Map<String, dynamic> soilStatus;
  final String source;

  const SensorResult({
    required this.healthScore, required this.ndviProxy,
    required this.n, required this.p, required this.k,
    required this.ph, required this.ec,
    required this.moisture, required this.temperature,
    required this.carbon, required this.co2Equivalent,
    required this.recommendations, required this.soilStatus,
    required this.source,
  });

  factory SensorResult.fromJson(Map<String, dynamic> j) {
    final soil = (j['soil'] as Map?)?.cast<String, dynamic>() ?? {};
    final carbonMap = (j['carbon'] as Map?)?.cast<String, dynamic>() ?? {};
    final recs = (j['recommendations'] as List?)?.cast<String>() ?? [];
    return SensorResult(
      healthScore:    (j['health_score'] as num?)?.toDouble() ?? 0,
      ndviProxy:      (j['ndvi_proxy']   as num?)?.toDouble() ?? 0,
      n:              (soil['n']           as num?)?.toDouble() ?? 0,
      p:              (soil['p']           as num?)?.toDouble() ?? 0,
      k:              (soil['k']           as num?)?.toDouble() ?? 0,
      ph:             (soil['ph']          as num?)?.toDouble() ?? 0,
      ec:             (soil['ec']          as num?)?.toDouble() ?? 0,
      moisture:       (soil['moisture']    as num?)?.toDouble() ?? 0,
      temperature:    (soil['temperature'] as num?)?.toDouble() ?? 0,
      carbon:         (carbonMap['carbon']         as num?)?.toDouble() ?? 0,
      co2Equivalent:  (carbonMap['co2_equivalent'] as num?)?.toDouble() ?? 0,
      recommendations: recs,
      soilStatus:     (j['soil_status'] as Map?)?.cast<String, dynamic>() ?? {},
      source:         j['source'] as String? ?? 'hardware',
    );
  }
}
