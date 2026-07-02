import 'package:flutter/material.dart';
import '../models/farmer.dart';
import 'sensor_data_service.dart';

const Color kAlertRed   = Color(0xFFE74C3C);
const Color kAlertAmber = Color(0xFFF39C12);

class MockData {
  MockData._();

  static final farmer = Farmer(
    id: 'demo-uid',
    name: 'Ramesh Kumar',
    phone: '+919597339997',
    village: 'Tanjavur',
    district: 'Tamil Nadu',
    farmSize: 1.0,
    crops: ['Rice'],
    joinDate: DateTime(2023, 3, 1),
    preferredLanguage: 'en',
  );

  static final farm = Farm(
    id: 'demo-farm-1',
    farmerId: 'demo-uid',
    name: 'Rice Farm',
    location: const GeoPoint(10.7867, 79.1378),
    area: 1.0,
    soilType: 'loamy',
    boundary: {},
    crops: ['Rice'],
    createdAt: DateTime(2023, 3, 1),
  );

  // ── Sensor data — zeros when hardware not connected ───────────────────────

  static SoilReading get soilReading => SensorDataService.instance.isConnected
      ? SensorDataService.instance.lastSoil
      : const SoilReading(n: 0, p: 0, k: 0, ph: 0, ec: 0, moisture: 0, temperature: 0);

  static CarbonReading get carbonReading => SensorDataService.instance.isConnected
      ? SensorDataService.instance.lastCarbon
      : const CarbonReading(biomass: 0, totalCarbon: 0, co2Equivalent: 0);

  static Analysis get analysis => Analysis(
    id: 'demo-analysis-1',
    farmId: 'demo-farm-1',
    timestamp: DateTime.now(),
    cropType: 'Rice',
    growthStage: SensorDataService.instance.isConnected ? 'Reproductive' : 'Not Connected',
    gpr: 0,
    healthScore: SensorDataService.instance.isConnected ? 82 : 0,
    soil: soilReading,
    carbon: carbonReading,
    ndvi: SensorDataService.instance.isConnected ? 0.68 : 0,
    recommendations: SensorDataService.instance.isConnected
        ? [
            'Nitrogen is 45% deficient — apply 146 kg Urea.',
            'Phosphorus is adequate. Skip DAP top-dressing.',
            'Maintain current irrigation. Soil moisture is optimal at 28%.',
          ]
        : ['Connect your sensor device to view recommendations.'],
  );

  static List<double> get ndviHistory => SensorDataService.instance.isConnected
      ? [0.31, 0.38, 0.45, 0.52, 0.58, 0.63, 0.68]
      : [0, 0, 0, 0, 0, 0, 0];

  static List<CarbonYear> get carbonHistory => SensorDataService.instance.isConnected
      ? [
          CarbonYear(2022, 45.0), CarbonYear(2023, 49.5),
          CarbonYear(2024, 53.8), CarbonYear(2025, 57.1), CarbonYear(2026, 59.3),
        ]
      : [
          CarbonYear(2022, 0), CarbonYear(2023, 0),
          CarbonYear(2024, 0), CarbonYear(2025, 0), CarbonYear(2026, 0),
        ];

  static List<CarbonCredit> get credits => SensorDataService.instance.isConnected
      ? [
          CarbonCredit(
            id: 'credit-1', farmerId: 'demo-uid', farmId: 'demo-farm-1',
            amount: 12.4, status: 'eligible',
          ),
          CarbonCredit(
            id: 'credit-2', farmerId: 'demo-uid', farmId: 'demo-farm-1',
            amount: 8.2, status: 'sold',
            salePrice: 17220,
            soldDate: DateTime(2025, 11, 14),
            paymentId: 'CARBON-TN-2025-00089',
          ),
        ]
      : [];

  static final alerts = [
    DemoAlert('🔴 HIGH', 'Nitrogen deficiency in North field', kAlertRed),
    DemoAlert('🟡 MEDIUM', 'Possible heat wave in 5 days', kAlertAmber),
  ];

  static final marketOffers = [
    MarketOffer(
      name: 'Government Market (CCTS)',
      icon: '🏛️',
      pricePerCredit: 2100,
      paymentDays: '3–5 days',
      tag: '',
    ),
    MarketOffer(
      name: 'International Buyer (Microsoft)',
      icon: '🌐',
      pricePerCredit: 2850,
      paymentDays: '7–10 days',
      tag: 'BEST PRICE',
    ),
    MarketOffer(
      name: 'Premium Buyer (Agroforestry)',
      icon: '🌱',
      pricePerCredit: 3600,
      paymentDays: '5–7 days',
      tag: 'HIGHEST PRICE',
    ),
  ];

  static final forecast = List.generate(15, (i) {
    final temps = [32,33,34,35,36,37,35,33,31,30,29,31,32,33,32];
    final rain  = [ 0, 0, 0, 0, 0, 5, 8,12, 4, 0, 0, 0, 0, 0, 0];
    final moist = [28,26,24,22,20,25,30,35,32,28,26,25,27,28,29];
    final risks = ['Low','Low','Low','Med','High','High','Med','Low',
                   'Low','Low','Low','Low','Low','Low','Low'];
    return ForecastDay(
      date: DateTime.now().add(Duration(days: i)),
      temp: temps[i], rain: rain[i],
      moisture: moist[i], risk: risks[i],
    );
  });

  static const double baselineCarbon  = 45.0;
  static const double currentCarbon   = 59.3;
  static const double additionalCarbon = 14.3;
  static const double co2eAdditional  = 52.6;
  static const double carbonStability = 94.0;
  static const double microbialHealth = 86.0;
  static const double sciIndex        = 68.0;
}

class DemoAlert {
  final String level, message;
  final Color color;
  const DemoAlert(this.level, this.message, this.color);
}

class CarbonYear {
  final int year;
  final double carbon;
  const CarbonYear(this.year, this.carbon);
}

class MarketOffer {
  final String name, icon, paymentDays, tag;
  final double pricePerCredit;
  const MarketOffer({
    required this.name, required this.icon, required this.pricePerCredit,
    required this.paymentDays, required this.tag,
  });
}

class ForecastDay {
  final DateTime date;
  final int temp, rain, moisture;
  final String risk;
  const ForecastDay({
    required this.date, required this.temp, required this.rain,
    required this.moisture, required this.risk,
  });
}
