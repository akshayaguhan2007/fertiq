import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class SeasonalData {
  final String seasonLabel;
  final double avgNdvi;
  final double estimatedYield;
  final double carbonSequestered;
  final double soilHealth;

  const SeasonalData({
    required this.seasonLabel,
    required this.avgNdvi,
    required this.estimatedYield,
    required this.carbonSequestered,
    required this.soilHealth,
  });
}

class SeasonalComparison {
  final SeasonalData current;
  final SeasonalData previous;

  const SeasonalComparison({required this.current, required this.previous});

  double diff(double Function(SeasonalData) getter) {
    final prev = getter(previous);
    if (prev == 0) return 0;
    return ((getter(current) - prev) / prev) * 100;
  }
}

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  List<Map<String, dynamic>> _history = [];

  /// Fetch sensor history from backend and compute seasonal comparison.
  Future<SeasonalComparison> getSeasonalComparison() async {
    // Fetch up to 40 readings to split into two halves
    try {
      final res = await http.get(
        Uri.parse('$kApiBase/sensor/history?limit=40'),
        headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _history = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    if (_history.isEmpty) {
      // No data yet — return zeros so UI shows "no data" state
      return SeasonalComparison(
        current:  SeasonalData(seasonLabel: 'Current Season',  avgNdvi: 0, estimatedYield: 0, carbonSequestered: 0, soilHealth: 0),
        previous: SeasonalData(seasonLabel: 'Previous Season', avgNdvi: 0, estimatedYield: 0, carbonSequestered: 0, soilHealth: 0),
      );
    }

    // Split history: newer half = current, older half = previous
    final mid     = (_history.length / 2).ceil();
    final current  = _history.sublist(0, mid);          // newest readings first
    final previous = _history.sublist(mid);

    double avg(List<Map<String, dynamic>> rows, String key) {
      if (rows.isEmpty) return 0;
      return rows.map((r) => (r[key] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / rows.length;
    }

    final curNdvi    = avg(current,  'ndvi_proxy');
    final prevNdvi   = avg(previous, 'ndvi_proxy');
    final curCarbon  = avg(current,  'carbon');
    final prevCarbon = avg(previous, 'carbon');

    // Estimate yield from NDVI: ~6 t/ha at NDVI 0.7
    double yieldFromNdvi(double ndvi) => (ndvi * 8.5).clamp(0, 15);
    // Soil health proxy from NDVI * 100
    double healthFromNdvi(double ndvi) => (ndvi * 100).clamp(0, 100);

    // Determine season labels from timestamps
    String seasonLabel(List<Map<String, dynamic>> rows) {
      if (rows.isEmpty) return 'Season';
      final ts = rows.first['timestamp'] as String?;
      if (ts == null) return 'Season';
      final dt = DateTime.tryParse(ts) ?? DateTime.now();
      final month = dt.month;
      final season = (month >= 6 && month <= 11) ? 'Kharif' : 'Rabi';
      return '$season ${dt.year}';
    }

    return SeasonalComparison(
      current: SeasonalData(
        seasonLabel:       seasonLabel(current),
        avgNdvi:           curNdvi,
        estimatedYield:    yieldFromNdvi(curNdvi),
        carbonSequestered: curCarbon,
        soilHealth:        healthFromNdvi(curNdvi),
      ),
      previous: SeasonalData(
        seasonLabel:       seasonLabel(previous),
        avgNdvi:           prevNdvi,
        estimatedYield:    yieldFromNdvi(prevNdvi),
        carbonSequestered: prevCarbon,
        soilHealth:        healthFromNdvi(prevNdvi),
      ),
    );
  }

  /// Weekly NDVI from real history (last 7 readings).
  List<double> currentNdviWeekly() {
    if (_history.isEmpty) return List.filled(7, 0);
    final slice = _history.take(7).toList();
    while (slice.length < 7) { slice.add(slice.last); }
    return slice.reversed.map((r) => (r['ndvi_proxy'] as num?)?.toDouble() ?? 0).toList();
  }

  /// Weekly NDVI from older half of history.
  List<double> previousNdviWeekly() {
    if (_history.length < 8) return List.filled(7, 0);
    final mid   = (_history.length / 2).ceil();
    final slice = _history.sublist(mid).take(7).toList();
    while (slice.length < 7) { slice.add(slice.last); }
    return slice.reversed.map((r) => (r['ndvi_proxy'] as num?)?.toDouble() ?? 0).toList();
  }
}
