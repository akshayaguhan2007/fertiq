import 'dart:convert';
import 'package:http/http.dart' as http;

// Replace with your Gemini API key (store in .env in production)
// Add your Gemini API key here when ready (AIzaSy...)
const String _kGeminiKey = '';
const String _kGeminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

class GeminiRecommendations {
  final String fertilizer;
  final String irrigation;
  final String pestManagement;
  final String harvestPlanning;
  final String carbonCredits;

  const GeminiRecommendations({
    required this.fertilizer,
    required this.irrigation,
    required this.pestManagement,
    required this.harvestPlanning,
    required this.carbonCredits,
  });

  List<String> get asList => [
        '🌱 Fertilizer: $fertilizer',
        '💧 Irrigation: $irrigation',
        '🐛 Pest Management: $pestManagement',
        '🌾 Harvest Planning: $harvestPlanning',
        '💰 Carbon Credits: $carbonCredits',
      ];

  static GeminiRecommendations fallback(double ndvi, String crop) {
    final isLow = ndvi < 0.4;
    return GeminiRecommendations(
      fertilizer: isLow
          ? 'Apply 120 kg/ha Urea and 60 kg/ha DAP to boost growth.'
          : 'Maintain current nutrition. Light top-dressing with 40 kg/ha Urea.',
      irrigation: ndvi < 0.5
          ? 'Increase irrigation frequency — moisture stress detected.'
          : 'Current irrigation schedule is adequate.',
      pestManagement:
          'Scout for $crop pests every 5 days. Apply neem oil if >5% leaf damage.',
      harvestPlanning: ndvi > 0.65
          ? 'Crop nearing maturity. Plan harvest in 15–20 days.'
          : 'Crop in mid-growth. Harvest expected in 45–60 days.',
      carbonCredits:
          'Estimated ${(ndvi * 14.3).toStringAsFixed(1)} t additional carbon — eligible for ₹${(ndvi * 14.3 * 3.67 * 2100 * 0.9).toStringAsFixed(0)} payout.',
    );
  }
}

class GeminiService {
  Future<GeminiRecommendations> getRecommendations({
    required String cropType,
    required String growthStage,
    required double ndvi,
    required double biomass,
    required double carbon,
    required double soilN,
    required double soilP,
    required double soilK,
    required String district,
    required String weatherSummary,
  }) async {
    if (_kGeminiKey.isEmpty) {
      return GeminiRecommendations.fallback(ndvi, cropType);
    }
    final prompt = '''
You are an agricultural AI assistant for small farmers in Tamil Nadu.
Based on the following data, provide 5 specific, actionable recommendations in simple English:

- Crop: $cropType
- Growth Stage: $growthStage
- NDVI: ${ndvi.toStringAsFixed(3)} (0=dead, 1=very healthy)
- Biomass: ${biomass.toStringAsFixed(2)} tons/ha
- Carbon: ${carbon.toStringAsFixed(2)} tons C/ha
- Soil N: ${soilN.toStringAsFixed(1)} ppm
- Soil P: ${soilP.toStringAsFixed(1)} ppm
- Soil K: ${soilK.toStringAsFixed(1)} ppm
- Location: $district, Tamil Nadu
- Weather: $weatherSummary

Respond ONLY in this exact JSON format (no markdown, no extra text):
{
  "fertilizer": "...",
  "irrigation": "...",
  "pestManagement": "...",
  "harvestPlanning": "...",
  "carbonCredits": "..."
}
''';

    try {
      final res = await http
          .post(
            Uri.parse('$_kGeminiUrl?key=$_kGeminiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 512},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final text = body['candidates'][0]['content']['parts'][0]['text'] as String;
        final cleaned = text.trim().replaceAll('```json', '').replaceAll('```', '').trim();
        final data = jsonDecode(cleaned) as Map<String, dynamic>;
        return GeminiRecommendations(
          fertilizer:     data['fertilizer']     as String? ?? '',
          irrigation:     data['irrigation']     as String? ?? '',
          pestManagement: data['pestManagement'] as String? ?? '',
          harvestPlanning: data['harvestPlanning'] as String? ?? '',
          carbonCredits:  data['carbonCredits']  as String? ?? '',
        );
      }
    } catch (_) {}

    return GeminiRecommendations.fallback(ndvi, cropType);
  }
}
