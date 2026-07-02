import '../services/mock_data.dart';

class SeasonalData {
  final String seasonLabel; // e.g. "Kharif 2024"
  final double avgNdvi;
  final double estimatedYield; // tons/ha
  final double carbonSequestered;
  final double soilHealth; // 0–100

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

  /// Returns current vs previous season comparison (mock data).
  Future<SeasonalComparison> getSeasonalComparison() async {
    await Future.delayed(const Duration(milliseconds: 600)); // sim network

    // Current season derived from MockData
    final ndviHistory = MockData.ndviHistory;
    final currentAvgNdvi = ndviHistory.sublist(3).reduce((a, b) => a + b) / 4;
    final prevAvgNdvi    = ndviHistory.sublist(0, 4).reduce((a, b) => a + b) / 4;

    final current = SeasonalData(
      seasonLabel: 'Kharif 2025',
      avgNdvi: currentAvgNdvi,
      estimatedYield: 5.8,
      carbonSequestered: MockData.currentCarbon,
      soilHealth: MockData.microbialHealth,
    );

    final previous = SeasonalData(
      seasonLabel: 'Kharif 2024',
      avgNdvi: prevAvgNdvi,
      estimatedYield: 4.9,
      carbonSequestered: MockData.baselineCarbon + 8.0,
      soilHealth: 74.0,
    );

    return SeasonalComparison(current: current, previous: previous);
  }

  /// Returns weekly NDVI values for current and previous seasons.
  List<double> currentNdviWeekly()  => [0.42, 0.50, 0.58, 0.63, 0.66, 0.68, 0.67];
  List<double> previousNdviWeekly() => [0.31, 0.37, 0.43, 0.49, 0.53, 0.56, 0.55];
}
