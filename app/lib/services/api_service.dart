import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Base URL of your FastAPI backend.
const String kApiBase = 'http://localhost:8000';

class ApiService {
  final String _base;
  ApiService({String? base}) : _base = base ?? kApiBase;

  // ── Live sensor reading from Pi ─────────────────────────────────────────

  /// Called by Flutter after the Pi posts a reading.
  /// Fetches the latest hardware reading for [farmId] from the backend.
  Future<SensorResult?> fetchLatestReading(String farmId) async {
    final token = AuthService.instance.token;
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_base/sensor/live'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
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

  /// Returns a zero-value result when sensor is not connected.
  SensorResult disconnectedResult() => const SensorResult(
    healthScore: 0, ndviProxy: 0,
    n: 0, p: 0, k: 0, ph: 0, ec: 0, moisture: 0, temperature: 0,
    carbon: 0, co2Equivalent: 0,
    recommendations: ['Connect your sensor device to view live data.'],
    soilStatus: {},
    source: 'disconnected',
  );
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
    final recs = (j['recommendations'] as List?)?.cast<String>() ?? [];
    return SensorResult(
      healthScore:    (j['health_score']   as num?)?.toDouble() ?? 0,
      ndviProxy:      (j['ndvi_proxy']     as num?)?.toDouble() ?? 0,
      n:              (j['n']              as num?)?.toDouble() ?? 0,
      p:              (j['p']              as num?)?.toDouble() ?? 0,
      k:              (j['k']              as num?)?.toDouble() ?? 0,
      ph:             (j['ph']             as num?)?.toDouble() ?? 0,
      ec:             (j['ec']             as num?)?.toDouble() ?? 0,
      moisture:       (j['moisture']       as num?)?.toDouble() ?? 0,
      temperature:    (j['temperature']    as num?)?.toDouble() ?? 0,
      carbon:         (j['carbon']         as num?)?.toDouble() ?? 0,
      co2Equivalent:  (j['co2_equivalent'] as num?)?.toDouble() ?? 0,
      recommendations: recs,
      soilStatus:     {},
      source:         j['source'] as String? ?? 'hardware',
    );
  }
}
