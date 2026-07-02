import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/mock_data.dart';
import 'cache_service.dart';

// Get free key at openweathermap.org/api
const String _kWeatherKey = 'YOUR_OPENWEATHERMAP_API_KEY';

class WeatherDay {
  final DateTime date;
  final int temp;
  final int rain;       // mm
  final int moisture;   // %
  final String risk;    // Low | Med | High
  final double humidity;
  final double windSpeed;

  const WeatherDay({
    required this.date, required this.temp, required this.rain,
    required this.moisture, required this.risk,
    required this.humidity, required this.windSpeed,
  });

  double get droughtRisk {
    if (rain > 10) return 0.05;
    if (moisture < 20) return 0.60;
    if (moisture < 30) return 0.30;
    return 0.10;
  }

  double get heatStressRisk {
    if (temp >= 40) return 0.90;
    if (temp >= 37) return 0.60;
    if (temp >= 34) return 0.35;
    return 0.10;
  }

  double get floodRisk {
    if (rain > 50) return 0.70;
    if (rain > 20) return 0.30;
    return 0.05;
  }

  double get overallRisk => (0.4 * droughtRisk + 0.2 * floodRisk + 0.4 * heatStressRisk).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(), 'temp': temp, 'rain': rain,
    'moisture': moisture, 'risk': risk, 'humidity': humidity, 'windSpeed': windSpeed,
  };

  factory WeatherDay.fromJson(Map<String, dynamic> j) => WeatherDay(
    date:      DateTime.parse(j['date'] as String),
    temp:      (j['temp'] as num).toInt(),
    rain:      (j['rain'] as num).toInt(),
    moisture:  (j['moisture'] as num).toInt(),
    risk:      j['risk'] as String,
    humidity:  (j['humidity'] as num).toDouble(),
    windSpeed: (j['windSpeed'] as num).toDouble(),
  );
}

class WeatherService {
  final _cache = CacheService();

  Future<List<WeatherDay>> getForecast({
    required double lat,
    required double lng,
  }) async {
    // Try cache first
    final cached = await _cache.getWeather();
    if (cached != null && cached['forecast'] != null) {
      final list = (cached['forecast'] as List)
          .map((e) => WeatherDay.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }

    if (_kWeatherKey != 'YOUR_OPENWEATHERMAP_API_KEY') {
      try {
        final uri = Uri.parse(
          'https://api.openweathermap.org/data/3.0/onecall'
          '?lat=$lat&lon=$lng&exclude=current,minutely,hourly,alerts'
          '&units=metric&appid=$_kWeatherKey',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final daily = (body['daily'] as List).take(15).toList();
          final days = daily.asMap().entries.map((entry) {
            final d = entry.value as Map<String, dynamic>;
            final temp = ((d['temp'] as Map)['max'] as num).toInt();
            final rain = ((d['rain'] as num?) ?? 0).toInt();
            final humidity = (d['humidity'] as num).toDouble();
            final wind = (d['wind_speed'] as num).toDouble();
            final moisture = (humidity * 0.45).toInt().clamp(15, 55);
            final risk = temp > 36 || rain > 30 ? 'High' : temp > 33 || rain > 10 ? 'Med' : 'Low';
            return WeatherDay(
              date: DateTime.fromMillisecondsSinceEpoch((d['dt'] as int) * 1000),
              temp: temp, rain: rain, moisture: moisture,
              risk: risk, humidity: humidity, windSpeed: wind,
            );
          }).toList();

          await _cache.setWeather({'forecast': days.map((d) => d.toJson()).toList()});
          return days;
        }
      } catch (_) {}
    }

    // Fallback to mock
    return MockData.forecast.map((f) => WeatherDay(
      date: f.date, temp: f.temp, rain: f.rain,
      moisture: f.moisture, risk: f.risk,
      humidity: 65.0, windSpeed: 12.0,
    )).toList();
  }

  /// Overall 15-day climate risk summary
  static Map<String, double> summariseRisk(List<WeatherDay> days) {
    if (days.isEmpty) return {'drought': 0, 'flood': 0, 'heat': 0, 'overall': 0};
    final drought  = days.map((d) => d.droughtRisk).reduce((a, b) => a + b) / days.length;
    final flood    = days.map((d) => d.floodRisk).reduce((a, b) => a + b) / days.length;
    final heat     = days.map((d) => d.heatStressRisk).reduce((a, b) => a + b) / days.length;
    final overall  = days.map((d) => d.overallRisk).reduce((a, b) => a + b) / days.length;
    return {'drought': drought, 'flood': flood, 'heat': heat, 'overall': overall};
  }
}
