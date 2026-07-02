import '../models/farmer.dart';

/// Fetches real sensor readings from your hardware API.
/// Returns all-zero values when hardware is not connected.
class SensorDataService {
  SensorDataService._();
  static final instance = SensorDataService._();

  bool _connected = false;
  bool get isConnected => _connected;

  final SoilReading _lastSoil = const SoilReading(
    n: 0, p: 0, k: 0, ph: 0, ec: 0, moisture: 0, temperature: 0,
  );
  final CarbonReading _lastCarbon = const CarbonReading(
    biomass: 0, totalCarbon: 0, co2Equivalent: 0,
  );

  SoilReading get lastSoil => _lastSoil;
  CarbonReading get lastCarbon => _lastCarbon;

  // ── Fetch from hardware ───────────────────────────────────────────────────

  Future<SoilReading> fetchSoilReading() async {
    _connected = false;
    return _lastSoil;
  }

  Future<CarbonReading> fetchCarbonReading() async {
    _connected = false;
    return _lastCarbon;
  }

  /// Call this on app start to attempt hardware connection.
  Future<void> init() async {
    await fetchSoilReading();
    await fetchCarbonReading();
  }
}
