import 'dart:io';
import 'dart:math';

/// Result of analysing a leaf/crop image from the camera.
class CameraAnalysisResult {
  final double greenPixelRatio;   // 0–100 %
  final double yellowPixelRatio;
  final double brownPixelRatio;
  final double purplePixelRatio;
  final double healthScore;       // 0–100
  final String leafColor;         // dominant colour label
  final List<String> deficiencies;
  final List<String> diseases;
  final List<String> recommendations;
  final String overallStatus;     // Healthy / Moderate / Poor

  const CameraAnalysisResult({
    required this.greenPixelRatio,
    required this.yellowPixelRatio,
    required this.brownPixelRatio,
    required this.purplePixelRatio,
    required this.healthScore,
    required this.leafColor,
    required this.deficiencies,
    required this.diseases,
    required this.recommendations,
    required this.overallStatus,
  });
}

class CameraAnalysisService {
  /// Analyse [imageFile] and return a [CameraAnalysisResult].
  /// Uses pixel-sampling heuristics (no ML model required).
  Future<CameraAnalysisResult> analyse(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    // ── Pixel sampling ────────────────────────────────────────────────────────
    // JPEG/PNG raw bytes: sample every ~200th byte triplet as a rough RGB proxy.
    // This is a lightweight heuristic — good enough for demo / offline use.
    int greenCount = 0, yellowCount = 0, brownCount = 0,
        purpleCount = 0, totalSamples = 0;

    // Skip JPEG header (first 3 bytes) and sample raw byte triplets
    final start = bytes.length > 500 ? 300 : 0;
    for (int i = start; i < bytes.length - 2; i += 201) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      totalSamples++;

      if (_isGreen(r, g, b))  { greenCount++; }
      else if (_isYellow(r, g, b)) { yellowCount++; }
      else if (_isBrown(r, g, b))  { brownCount++; }
      else if (_isPurple(r, g, b)) { purpleCount++; }
    }

    if (totalSamples == 0) totalSamples = 1;

    final green  = (greenCount  / totalSamples * 100).clamp(0.0, 100.0);
    final yellow = (yellowCount / totalSamples * 100).clamp(0.0, 100.0);
    final brown  = (brownCount  / totalSamples * 100).clamp(0.0, 100.0);
    final purple = (purpleCount / totalSamples * 100).clamp(0.0, 100.0);

    // ── Health score ──────────────────────────────────────────────────────────
    final health = (green * 1.0 - yellow * 0.5 - brown * 0.8 - purple * 0.4)
        .clamp(0.0, 100.0);

    // ── Dominant colour ───────────────────────────────────────────────────────
    final maxVal = [green, yellow, brown, purple].reduce(max);
    String leafColor;
    if (maxVal == green)       leafColor = 'Green';
    else if (maxVal == yellow) leafColor = 'Yellow-Green';
    else if (maxVal == brown)  leafColor = 'Brown';
    else                       leafColor = 'Purple-Red';

    // ── Deficiency detection ──────────────────────────────────────────────────
    final deficiencies = <String>[];
    if (yellow > 20) { deficiencies.add('Nitrogen deficiency (pale/yellow leaves)'); }
    if (purple > 10) { deficiencies.add('Phosphorus deficiency (purple/red leaves)'); }
    if (brown  > 15) { deficiencies.add('Potassium deficiency (brown leaf tips)'); }

    // ── Disease detection ─────────────────────────────────────────────────────
    final diseases = <String>[];
    if (brown > 25 && yellow > 10) { diseases.add('Possible blight detected'); }
    if (brown > 20 && purple > 5)  { diseases.add('Possible rust infection'); }
    if (yellow > 30 && green < 30) { diseases.add('Possible mosaic virus / chlorosis'); }

    // ── Recommendations ───────────────────────────────────────────────────────
    final recs = <String>[];
    if (deficiencies.contains('Nitrogen deficiency (pale/yellow leaves)')) {
      recs.add('Apply Urea (46% N) at 40–60 kg/ha immediately.');
    }
    if (deficiencies.contains('Phosphorus deficiency (purple/red leaves)')) {
      recs.add('Apply DAP or SSP at 30 kg/ha to correct phosphorus.');
    }
    if (deficiencies.contains('Potassium deficiency (brown leaf tips)')) {
      recs.add('Apply MOP (Muriate of Potash) at 25 kg/ha.');
    }
    if (diseases.isNotEmpty) {
      recs.add('Isolate affected plants. Apply fungicide / neem oil spray.');
      recs.add('Remove and destroy severely infected leaves.');
    }
    if (green > 60) {
      recs.add('Crop looks healthy. Maintain current irrigation & nutrition.');
    }
    if (recs.isEmpty) {
      recs.add('Monitor crop closely. Rescan in 3–5 days.');
    }

    final status = health > 65 ? 'Healthy' : health > 35 ? 'Moderate' : 'Poor';

    return CameraAnalysisResult(
      greenPixelRatio:  green,
      yellowPixelRatio: yellow,
      brownPixelRatio:  brown,
      purplePixelRatio: purple,
      healthScore:      health,
      leafColor:        leafColor,
      deficiencies:     deficiencies,
      diseases:         diseases,
      recommendations:  recs,
      overallStatus:    status,
    );
  }

  // ── Colour classifiers ────────────────────────────────────────────────────
  bool _isGreen(int r, int g, int b) =>
      g > 80 && g > r * 1.2 && g > b * 1.1;

  bool _isYellow(int r, int g, int b) =>
      r > 150 && g > 150 && b < 100 && (r - b).abs() < 80;

  bool _isBrown(int r, int g, int b) =>
      r > 100 && g < 100 && b < 80 && r > g && r > b;

  bool _isPurple(int r, int g, int b) =>
      r > 80 && b > 80 && g < 80 && (r + b) > g * 2;
}
