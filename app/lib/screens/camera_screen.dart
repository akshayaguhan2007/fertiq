import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/camera_analysis_service.dart';
import '../services/app_strings.dart';
import '../theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker  = ImagePicker();
  final _service = CameraAnalysisService();

  File?                 _image;
  CameraAnalysisResult? _result;
  bool                  _loading = false;

  Future<void> _pick(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (xfile == null) return;
    final file = File(xfile.path);
    setState(() { _image = file; _result = null; _loading = true; });
    final result = await _service.analyse(file);
    setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        title: Text(t.cameraAnalysis),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(t.cameraInfoBanner,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kPrimary))),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Image preview ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => _pick(ImageSource.camera),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kBgWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorder, width: 2),
                ),
                child: _image == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.camera_alt_rounded, size: 56,
                            color: kPrimary.withValues(alpha: 0.4)),
                        const SizedBox(height: 10),
                        Text(t.tapToCapture,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: kTextGrey)),
                      ])
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover,
                            width: double.infinity, height: 220),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Buttons ──────────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(t.openCamera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: Text(t.chooseGallery),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Loading ──────────────────────────────────────────────────────
            if (_loading)
              Center(child: Column(children: [
                const CircularProgressIndicator(color: kPrimary),
                const SizedBox(height: 12),
                Text(t.analysingLeaf,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600)),
              ])),

            // ── Results ──────────────────────────────────────────────────────
            if (_result != null) ...[
              _HealthScoreCard(result: _result!, t: t),
              const SizedBox(height: 14),
              _ColorBreakdownCard(result: _result!, t: t),
              const SizedBox(height: 14),
              if (_result!.deficiencies.isNotEmpty)
                _ListCard(
                  title: t.deficienciesFound,
                  icon: Icons.warning_amber_rounded,
                  color: kAmber,
                  items: _result!.deficiencies,
                ),
              if (_result!.diseases.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ListCard(
                  title: t.diseasesDetected,
                  icon: Icons.coronavirus_outlined,
                  color: kRed,
                  items: _result!.diseases,
                ),
              ],
              const SizedBox(height: 14),
              _ListCard(
                title: t.recommendations,
                icon: Icons.tips_and_updates_rounded,
                color: kPrimary,
                items: _result!.recommendations,
              ),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Health Score Card ─────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final CameraAnalysisResult result;
  final AppStrings t;
  const _HealthScoreCard({required this.result, required this.t});

  @override
  Widget build(BuildContext context) {
    final score = result.healthScore;
    final color = score > 65 ? kGreenSoft : score > 35 ? kAmber : kRed;
    final status = score > 65 ? t.healthy : score > 35 ? t.moderate : t.stressed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: kShadowSm,
      ),
      child: Row(children: [
        SizedBox(
          width: 90, height: 90,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${score.round()}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              Text('/100', style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: kTextGrey)),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.leafHealthScore,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: kTextGrey, letterSpacing: 1)),
          const SizedBox(height: 6),
          StatusBadge(status, color),
          const SizedBox(height: 8),
          Text('${t.dominantColor}: ${result.leafColor}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextMid)),
          Text('${t.greenPixelRatio}: ${result.greenPixelRatio.toStringAsFixed(1)}%',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: kGreenSoft, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}

// ── Color Breakdown Card ──────────────────────────────────────────────────────

class _ColorBreakdownCard extends StatelessWidget {
  final CameraAnalysisResult result;
  final AppStrings t;
  const _ColorBreakdownCard({required this.result, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: kShadowSm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.colorAnalysis,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
        const SizedBox(height: 14),
        _ColorBar(label: t.greenColor,  value: result.greenPixelRatio,  color: kGreenSoft),
        _ColorBar(label: t.yellowColor, value: result.yellowPixelRatio, color: kAmber),
        _ColorBar(label: t.brownColor,  value: result.brownPixelRatio,  color: const Color(0xFF8B4513)),
        _ColorBar(label: t.purpleColor, value: result.purplePixelRatio, color: kPurple),
      ]),
    );
  }
}

class _ColorBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ColorBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: kTextMid)),
            Text('${value.toStringAsFixed(1)}%',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ]),
      );
}

// ── Generic List Card ─────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  const _ListCard({required this.title, required this.icon,
      required this.color, required this.items});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
          ]),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text('${e.key + 1}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, fontWeight: FontWeight.w700, color: color))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: kTextMid, height: 1.4))),
                ]),
              )),
        ]),
      );
}
