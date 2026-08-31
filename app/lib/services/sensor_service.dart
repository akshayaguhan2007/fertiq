import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'cache_service.dart';

class LiveSensorData {
  final double n, p, k, ph, ec, moisture, temperature;
  final double healthScore, ndviProxy, carbon, co2Equivalent;
  final List<String> recommendations;
  final String source;   // 'hardware' | 'cache' | 'mock'
  final DateTime timestamp;

  const LiveSensorData({
    required this.n, required this.p, required this.k,
    required this.ph, required this.ec,
    required this.moisture, required this.temperature,
    required this.healthScore, required this.ndviProxy,
    required this.carbon, required this.co2Equivalent,
    required this.recommendations,
    required this.source, required this.timestamp,
  });

  // Threshold alerts
  List<SensorAlert> get alerts {
    final list = <SensorAlert>[];
    if (n < 30)         list.add(SensorAlert('Nitrogen LOW',    'Apply Urea immediately. N=$n ppm (optimal: 40–80)',    AlertLevel.high));
    if (n > 120)        list.add(SensorAlert('Nitrogen HIGH',   'Risk of nitrogen burn. Reduce fertilizer.',           AlertLevel.medium));
    if (p < 15)         list.add(SensorAlert('Phosphorus LOW',  'Apply DAP. P=$p ppm (optimal: 20–40)',                AlertLevel.medium));
    if (k < 80)         list.add(SensorAlert('Potassium LOW',   'Apply MOP. K=$k ppm (optimal: 100–200)',              AlertLevel.medium));
    if (ph < 5.5)       list.add(SensorAlert('pH too LOW',      'Apply lime to raise pH. Current: $ph',                AlertLevel.high));
    if (ph > 7.8)       list.add(SensorAlert('pH too HIGH',     'Apply sulfur to lower pH. Current: $ph',              AlertLevel.medium));
    if (moisture < 18)  list.add(SensorAlert('Moisture LOW',    'Irrigate immediately. Moisture: $moisture%',          AlertLevel.high));
    if (moisture > 55)  list.add(SensorAlert('Moisture HIGH',   'Waterlogging risk. Check drainage.',                  AlertLevel.medium));
    if (temperature > 40) list.add(SensorAlert('Heat Stress',   'Temperature $temperature°C — protect crops.',         AlertLevel.high));
    return list;
  }

  Map<String, dynamic> toJson() => {
    'n': n, 'p': p, 'k': k, 'ph': ph, 'ec': ec,
    'moisture': moisture, 'temperature': temperature,
    'healthScore': healthScore, 'ndviProxy': ndviProxy,
    'carbon': carbon, 'co2Equivalent': co2Equivalent,
    'recommendations': recommendations,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LiveSensorData.fromJson(Map<String, dynamic> j, String src) => LiveSensorData(
    n: (j['n'] as num).toDouble(), p: (j['p'] as num).toDouble(), k: (j['k'] as num).toDouble(),
    ph: (j['ph'] as num).toDouble(), ec: (j['ec'] as num).toDouble(),
    moisture: (j['moisture'] as num).toDouble(), temperature: (j['temperature'] as num).toDouble(),
    healthScore: (j['healthScore'] as num).toDouble(),
    ndviProxy: (j['ndviProxy'] as num).toDouble(),
    carbon: (j['carbon'] as num).toDouble(), co2Equivalent: (j['co2Equivalent'] as num).toDouble(),
    recommendations: (j['recommendations'] as List?)?.cast<String>() ?? [],
    source: src, timestamp: DateTime.parse(j['timestamp'] as String),
  );

  static LiveSensorData disconnected() => LiveSensorData(
    n: 0, p: 0, k: 0, ph: 0, ec: 0, moisture: 0, temperature: 0,
    healthScore: 0, ndviProxy: 0, carbon: 0, co2Equivalent: 0,
    recommendations: [],
    source: 'disconnected', timestamp: DateTime.now(),
  );
}

enum AlertLevel { high, medium, low }

class SensorAlert {
  final String title, message;
  final AlertLevel level;
  const SensorAlert(this.title, this.message, this.level);
}

class SensorService {
  final _cache = CacheService();
  Timer? _pollTimer;
  final _controller = StreamController<LiveSensorData>.broadcast();
  LiveSensorData? _lastGoodData;

  Stream<LiveSensorData> get stream => _controller.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Start polling every [intervalSeconds] seconds
  void startPolling({int intervalSeconds = 2}) {
    _fetch();
    _pollTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => _fetch());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    stopPolling();
    _controller.close();
  }

  Future<void> _fetch() async {
    final data = await fetchOnce();
    if (!_controller.isClosed) _controller.add(data);
  }

  /// Single fetch — tries /sensor/live (Neon DB via FastAPI), falls back to last reading
  Future<LiveSensorData> fetchOnce() async {
    // 1. Try FastAPI /sensor/live (reads latest row from Neon DB written by Pi)
    try {
      final res = await http.get(
        Uri.parse('$kApiBase/sensor/live'),
        headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = LiveSensorData(
          n:             (body['n']             as num?)?.toDouble() ?? 0,
          p:             (body['p']             as num?)?.toDouble() ?? 0,
          k:             (body['k']             as num?)?.toDouble() ?? 0,
          ph:            (body['ph']            as num?)?.toDouble() ?? 7.0,
          ec:            (body['ec']            as num?)?.toDouble() ?? 0,
          moisture:      (body['moisture']      as num?)?.toDouble() ?? 0,
          temperature:   (body['temperature']   as num?)?.toDouble() ?? 25,
          healthScore:   (body['health_score']  as num?)?.toDouble() ?? 0,
          ndviProxy:     (body['ndvi_proxy']    as num?)?.toDouble() ?? 0,
          carbon:        (body['carbon']        as num?)?.toDouble() ?? 0,
          co2Equivalent: (body['co2_equivalent'] as num?)?.toDouble() ?? 0,
          recommendations: (body['recommendations'] as List?)?.cast<String>() ?? [],
          source: 'hardware', timestamp: DateTime.now(),
        );
        _isConnected = true;
        _lastGoodData = data;
        await _cache.setSensor(data.toJson());
        return data;
      }
    } on SocketException {
      _isConnected = false;
    } catch (_) {
      _isConnected = false;
    }

    // 2. Sensor offline — return last good reading with source 'last'
    if (_lastGoodData != null) {
      return LiveSensorData(
        n: _lastGoodData!.n, p: _lastGoodData!.p, k: _lastGoodData!.k,
        ph: _lastGoodData!.ph, ec: _lastGoodData!.ec,
        moisture: _lastGoodData!.moisture, temperature: _lastGoodData!.temperature,
        healthScore: _lastGoodData!.healthScore, ndviProxy: _lastGoodData!.ndviProxy,
        carbon: _lastGoodData!.carbon, co2Equivalent: _lastGoodData!.co2Equivalent,
        recommendations: _lastGoodData!.recommendations,
        source: 'last', timestamp: _lastGoodData!.timestamp,
      );
    }

    // 3. Try persistent cache (app restart with no sensor yet)
    final cached = await _cache.getSensor();
    if (cached != null) {
      final d = LiveSensorData.fromJson(cached, 'last');
      _lastGoodData = d;
      return d;
    }

    // 4. Never had a reading — return zeros
    return LiveSensorData.disconnected();
  }
}
