import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farmer.dart';
import 'auth_service.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final String _base = kApiBase;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthService.instance.token}',
  };

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<bool> profileExists() async {
    try {
      final res = await http.get(Uri.parse('$_base/profile'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['exists'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<Farmer?> getFarmer() async {
    try {
      final res = await http.get(Uri.parse('$_base/profile'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        if (d['exists'] != true) return null;
        return _farmerFromMap(d);
      }
    } catch (_) {}
    return null;
  }

  Stream<Farmer?> farmerStream() async* {
    yield await getFarmer();
  }

  Future<void> saveProfile({
    required String name,
    required String phone,
    required String village,
    required String district,
    required double farmSize,
    required List<String> crops,
    required String preferredLanguage,
  }) async {
    await http.post(
      Uri.parse('$_base/profile'),
      headers: _headers,
      body: jsonEncode({
        'name': name, 'phone': phone, 'village': village,
        'district': district, 'farm_size': farmSize,
        'crops': crops, 'preferred_language': preferredLanguage,
      }),
    ).timeout(const Duration(seconds: 10));
  }

  // ── Farms ─────────────────────────────────────────────────────────────────

  Stream<List<Farm>> farmsStream() async* {
    yield await _fetchFarms();
  }

  Future<List<Farm>> _fetchFarms() async {
    try {
      final res = await http.get(Uri.parse('$_base/farms'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => _farmFromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Farm?> getFarm(String id) async {
    final farms = await _fetchFarms();
    try { return farms.firstWhere((f) => f.id == id); } catch (_) { return null; }
  }

  // ── Analyses ──────────────────────────────────────────────────────────────

  Stream<List<Analysis>> analysesStream(String farmId) async* {
    yield await _fetchAnalyses(farmId);
  }

  Future<List<Analysis>> _fetchAnalyses(String farmId) async {
    try {
      final res = await http.get(Uri.parse('$_base/analyses/$farmId'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => _analysisFromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Analysis?> getLatestAnalysis(String farmId) async {
    final list = await _fetchAnalyses(farmId);
    return list.isEmpty ? null : list.first;
  }

  // ── Carbon credits ────────────────────────────────────────────────────────

  Stream<List<CarbonCredit>> carbonCreditsStream() async* {
    try {
      final res = await http.get(Uri.parse('$_base/carbon-credits'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        yield list.map((e) => _creditFromMap(e as Map<String, dynamic>)).toList();
        return;
      }
    } catch (_) {}
    yield [];
  }

  // ── Climate alerts ────────────────────────────────────────────────────────

  Stream<List<ClimateAlert>> climateAlertsStream(String farmId) async* {
    try {
      final res = await http.get(Uri.parse('$_base/climate-alerts/$farmId'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        yield list.map((e) => _alertFromMap(e as Map<String, dynamic>)).toList();
        return;
      }
    } catch (_) {}
    yield [];
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Stream<List<Payment>> paymentsStream() async* {
    try {
      final res = await http.get(Uri.parse('$_base/payments'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        yield list.map((e) => _paymentFromMap(e as Map<String, dynamic>)).toList();
        return;
      }
    } catch (_) {}
    yield [];
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  Farmer _farmerFromMap(Map<String, dynamic> d) => Farmer(
    id:                AuthService.instance.userId ?? '',
    name:              d['name'] as String? ?? '',
    phone:             d['phone'] as String? ?? '',
    village:           d['village'] as String? ?? '',
    district:          d['district'] as String? ?? '',
    farmSize:          (d['farm_size'] as num?)?.toDouble() ?? 0,
    crops:             (d['crops'] as List?)?.cast<String>() ?? [],
    preferredLanguage: d['preferred_language'] as String? ?? 'en',
    joinDate:          DateTime.tryParse(d['join_date'] as String? ?? '') ?? DateTime.now(),
  );

  Farm _farmFromMap(Map<String, dynamic> d) => Farm(
    id:        d['id'] as String? ?? '',
    farmerId:  d['farmer_id'] as String? ?? '',
    name:      d['name'] as String? ?? '',
    soilType:  d['soil_type'] as String? ?? '',
    location:  GeoPoint(
      (d['lat'] as num?)?.toDouble() ?? 0,
      (d['lng'] as num?)?.toDouble() ?? 0,
    ),
    area:      (d['area'] as num?)?.toDouble() ?? 0,
    boundary:  (d['boundary'] as Map<String, dynamic>?) ?? {},
    crops:     (d['crops'] as List?)?.cast<String>() ?? [],
    createdAt: DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Analysis _analysisFromMap(Map<String, dynamic> d) {
    final soil = (d['soil'] as Map<String, dynamic>?) ?? {};
    final carb = (d['carbon'] as Map<String, dynamic>?) ?? {};
    return Analysis(
      id:          d['id'] as String? ?? '',
      farmId:      d['farm_id'] as String? ?? '',
      cropType:    d['crop_type'] as String? ?? '',
      growthStage: d['growth_stage'] as String? ?? '',
      timestamp:   DateTime.tryParse(d['timestamp'] as String? ?? '') ?? DateTime.now(),
      gpr:         (d['gpr'] as num?)?.toDouble() ?? 0,
      healthScore: (d['health_score'] as num?)?.toDouble() ?? 0,
      ndvi:        (d['ndvi'] as num?)?.toDouble() ?? 0,
      soil: SoilReading(
        n: (soil['n'] as num?)?.toDouble() ?? 0,
        p: (soil['p'] as num?)?.toDouble() ?? 0,
        k: (soil['k'] as num?)?.toDouble() ?? 0,
        ph: (soil['ph'] as num?)?.toDouble() ?? 0,
        ec: (soil['ec'] as num?)?.toDouble() ?? 0,
        moisture: (soil['moisture'] as num?)?.toDouble() ?? 0,
        temperature: (soil['temperature'] as num?)?.toDouble() ?? 0,
      ),
      carbon: CarbonReading(
        biomass:       (carb['biomass'] as num?)?.toDouble() ?? 0,
        totalCarbon:   (carb['totalCarbon'] as num?)?.toDouble() ?? 0,
        co2Equivalent: (carb['co2Equivalent'] as num?)?.toDouble() ?? 0,
      ),
      recommendations: (d['recommendations'] as List?)?.cast<String>() ?? [],
      imageUrl: d['image_url'] as String?,
    );
  }

  CarbonCredit _creditFromMap(Map<String, dynamic> d) => CarbonCredit(
    id:        d['id'] as String? ?? '',
    farmerId:  d['farmer_id'] as String? ?? '',
    farmId:    d['farm_id'] as String? ?? '',
    amount:    (d['amount'] as num?)?.toDouble() ?? 0,
    status:    d['status'] as String? ?? '',
    salePrice: (d['sale_price'] as num?)?.toDouble(),
    soldDate:  d['sold_date'] != null ? DateTime.tryParse(d['sold_date'] as String) : null,
    paymentId: d['payment_id'] as String?,
  );

  ClimateAlert _alertFromMap(Map<String, dynamic> d) => ClimateAlert(
    id:             d['id'] as String? ?? '',
    farmId:         d['farm_id'] as String? ?? '',
    type:           d['type'] as String? ?? '',
    severity:       d['severity'] as String? ?? '',
    riskPercentage: (d['risk_percentage'] as num?)?.toDouble() ?? 0,
    recommendation: d['recommendation'] as String? ?? '',
    createdAt:      DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Payment _paymentFromMap(Map<String, dynamic> d) => Payment(
    id:        d['id'] as String? ?? '',
    creditId:  d['credit_id'] as String? ?? '',
    farmerId:  d['farmer_id'] as String? ?? '',
    farmId:    d['farm_id'] as String? ?? '',
    amount:    (d['amount'] as num?)?.toDouble() ?? 0,
    paymentId: d['payment_id'] as String? ?? '',
    status:    d['status'] as String? ?? '',
    createdAt: DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
