import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/mock_data.dart';
import '../services/pdf_service.dart';
import '../theme.dart';

class CarbonReportScreen extends StatelessWidget {
  const CarbonReportScreen({super.key});

  Future<void> _downloadCertificate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Generating certificate…'), duration: Duration(seconds: 2)),
      );
      final bytes = await PdfService.instance.generateCertificate(
        farmerName: MockData.farmer.name,
        farmName: MockData.farm.name,
        location: '${MockData.farmer.village}, TN',
        carbonCredits: MockData.co2eAdditional,
        co2eReduced: MockData.co2eAdditional,
        transactionId: 'CARBON-TN-2025-00089',
        issuedDate: DateTime.now(),
      );
      // Show print/share dialog via printing package
      await Printing.sharePdf(bytes: bytes, filename: 'carbon-certificate.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextDark, size: 16),
              onPressed: () => context.go('/dashboard'),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.eco_rounded, color: kPrimary, size: 14),
              const SizedBox(width: 4),
              Text('Carbon', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary)),
            ]),
          ),
        ],
      ),
      body: ListView(children: [
        // ── Hero image ─────────────────────────────────────
        _HeroImage(),

        // ── White rounded container (like shop detail screen) ─
        TopRoundedContainer(
          color: kBgWhite,
          child: Column(children: [
            const SizedBox(height: 24),
            _SummarySection(),
            TopRoundedContainer(
              color: kBgPage,
              child: Column(children: [
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _CreditsCard(context: context)),
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _TrendChart()),
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _StabilityCard()),
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _ImpactCard()),
                const SizedBox(height: 100),
              ]),
            ),
          ]),
        ),
      ]),

      bottomNavigationBar: TopRoundedContainer(
        color: kBgWhite,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadCertificate(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Certificate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/sell'),
                  icon: const Icon(Icons.sell_rounded, size: 18),
                  label: const Text('Sell Credits'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 260,
        child: CachedNetworkImage(
          imageUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=700&q=80',
          fit: BoxFit.cover, width: double.infinity,
          placeholder: (_, _) => Container(color: kPrimaryLight),
          errorWidget: (_, _, _) => Container(color: kPrimaryLight,
              child: const Icon(Icons.eco_rounded, color: kPrimary, size: 80)),
        ),
      );
}

class _SummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StatusBadge('Verified', kPrimary),
            const Spacer(),
            Text(DateFormat('MMM yyyy').format(DateTime.now()),

                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextGrey)),
          ]),
          const SizedBox(height: 10),
          Text('Carbon Report', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: kTextDark)),
          const SizedBox(height: 4),
          Text('${MockData.farm.name}  ·  ${MockData.farm.area} ha  ·  Tanjavur, TN',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
          const SizedBox(height: 16),
          Row(children: [
            _BigStat(MockData.currentCarbon.toStringAsFixed(1), 'tons C/ha', kPrimary),
            Container(width: 1, height: 44, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 16)),
            _BigStat(MockData.carbonReading.co2Equivalent.toStringAsFixed(1), 'tons CO₂e/ha', kGreenSoft),
            Container(width: 1, height: 44, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 16)),
            _BigStat('${MockData.carbonStability.round()}%', 'Stability', kAccentBlue),
          ]),
          const SizedBox(height: 20),
        ]),
      );
}

class _BigStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _BigStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
        ]),
      );
}

class _CreditsCard extends StatelessWidget {
  final BuildContext context;
  const _CreditsCard({required this.context});

  @override
  Widget build(BuildContext context) {
    final value = (MockData.co2eAdditional * 3600).toStringAsFixed(0);
    return GlassCard(
      glow: true,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Carbon Credits', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
          StatusBadge('ELIGIBLE', kAccentGold),
        ]),
        const SizedBox(height: 16),
        _CreditLine('Baseline (5 yrs ago)', '${MockData.baselineCarbon} t C', kTextGrey),
        _CreditLine('Current',              '${MockData.currentCarbon} t C',  kTextMid),
        _CreditLine('Additional',           '${MockData.additionalCarbon} t C', kPrimary),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: kBorder)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Best rate', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
          Text('₹3,600 / credit', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kAccentGold)),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
          child: Text('You can earn  ₹$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: kPrimary)),
        ),
      ]),
    );
  }
}

class _CreditLine extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CreditLine(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

class _TrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = MockData.carbonHistory;
    final spots = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.carbon)).toList();
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('5-Year Trend', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
          Row(children: [
            const Icon(Icons.trending_up_rounded, color: kPrimary, size: 14),
            const SizedBox(width: 4),
            Text('+31.8%', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary)),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 130, child: LineChart(LineChartData(
          minY: 38, maxY: 66,
          gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= history.length) return const SizedBox.shrink();
                return Text('${history[i].year}', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey));
              },
            )),
          ),
          lineBarsData: [LineChartBarData(
            spots: spots, isCurved: true, color: kPrimary, barWidth: 3,
            dotData: FlDotData(show: true,
              getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                radius: 5, color: kPrimary, strokeWidth: 2.5, strokeColor: kBgWhite)),
            belowBarData: BarAreaData(show: true,
              gradient: LinearGradient(
                colors: [kPrimary.withValues(alpha: 0.15), kPrimary.withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          )],
        ))),
      ]),
    );
  }
}

class _StabilityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Carbon Stability', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(height: 16),
          _BarRow('5+ year permanence', MockData.carbonStability / 100, '${MockData.carbonStability.round()}%', kPrimary),
          const SizedBox(height: 12),
          _BarRow('Microbial health', MockData.microbialHealth / 100, '${MockData.microbialHealth.round()}%', kAccentBlue),
        ]),
      );
}

class _BarRow extends StatelessWidget {
  final String label, text;
  final double value;
  final Color color;
  const _BarRow(this.label, this.value, this.text, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextMid)),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12), color: color),
        ),
      ]);
}

class _ImpactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary.withValues(alpha: 0.08), kAccentBlue.withValues(alpha: 0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Environmental Impact', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(height: 14),
          Row(children: [
            _ImpactTile('🚗', '47', 'Cars off road\nper year', kAccentBlue),
            const SizedBox(width: 10),
            _ImpactTile('🌳', '2,400', 'Trees planted\nequivalent', kPrimary),
          ]),
        ]),
      );
}

class _ImpactTile extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _ImpactTile(this.emoji, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kBgWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey, height: 1.4)),
          ]),
        ),
      );
}


