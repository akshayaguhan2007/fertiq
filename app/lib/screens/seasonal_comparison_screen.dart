import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/analytics_service.dart';
import '../theme.dart';

class SeasonalComparisonScreen extends StatefulWidget {
  const SeasonalComparisonScreen({super.key});

  @override
  State<SeasonalComparisonScreen> createState() => _SeasonalComparisonScreenState();
}

class _SeasonalComparisonScreenState extends State<SeasonalComparisonScreen> {
  SeasonalComparison? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AnalyticsService.instance.getSeasonalComparison();
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        title: const Text('Seasonal Comparison'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _Body(data: _data!),
    );
  }
}

class _Body extends StatelessWidget {
  final SeasonalComparison data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Season labels legend
        _LegendRow(current: data.current.seasonLabel, previous: data.previous.seasonLabel),
        const SizedBox(height: 16),

        // Summary diff cards
        _DiffCardGrid(data: data),
        const SizedBox(height: 20),

        // NDVI trend chart
        _ChartCard(
          title: 'NDVI Trend',
          current: AnalyticsService.instance.currentNdviWeekly(),
          previous: AnalyticsService.instance.previousNdviWeekly(),
          maxY: 1.0,
          unit: '',
        ),
        const SizedBox(height: 16),

        // Carbon chart
        _ChartCard(
          title: 'Carbon Sequestered (t C/ha)',
          current: List.generate(7, (i) => data.current.carbonSequestered * (0.7 + i * 0.05)),
          previous: List.generate(7, (i) => data.previous.carbonSequestered * (0.7 + i * 0.04)),
          maxY: 75,
          unit: ' t',
        ),
        const SizedBox(height: 16),

        // Soil health bar comparison
        _SoilHealthCard(data: data),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String current, previous;
  const _LegendRow({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) => Row(children: [
        _Dot(kPrimary), const SizedBox(width: 6),
        Text(current, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
        const SizedBox(width: 20),
        _Dot(kAccentBlue), const SizedBox(width: 6),
        Text(previous, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextMid)),
      ]);
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) =>
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _DiffCardGrid extends StatelessWidget {
  final SeasonalComparison data;
  const _DiffCardGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _DiffMeta('NDVI', data.current.avgNdvi.toStringAsFixed(3),
          data.diff((d) => d.avgNdvi), Icons.satellite_alt_rounded),
      _DiffMeta('Yield', '${data.current.estimatedYield} t/ha',
          data.diff((d) => d.estimatedYield), Icons.grass_rounded),
      _DiffMeta('Carbon', '${data.current.carbonSequestered.toStringAsFixed(1)} t',
          data.diff((d) => d.carbonSequestered), Icons.eco_rounded),
      _DiffMeta('Soil Health', '${data.current.soilHealth.round()}%',
          data.diff((d) => d.soilHealth), Icons.opacity_rounded),
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
      children: metrics.map((m) => _DiffCard(meta: m)).toList(),
    );
  }
}

class _DiffMeta {
  final String label, value;
  final double diffPct;
  final IconData icon;
  const _DiffMeta(this.label, this.value, this.diffPct, this.icon);
}

class _DiffCard extends StatelessWidget {
  final _DiffMeta meta;
  const _DiffCard({required this.meta});

  Color get _color => meta.diffPct >= 0 ? kPrimary : kAccentRed;
  String get _arrow => meta.diffPct >= 0 ? '↑' : '↓';

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: kShadowSm,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(meta.icon, color: _color, size: 16),
            const SizedBox(width: 6),
            Text(meta.label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey)),
          ]),
          const Spacer(),
          Text(meta.value,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
          const SizedBox(height: 2),
          Row(children: [
            Text('$_arrow ${meta.diffPct.abs().toStringAsFixed(1)}%',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
            Text(' vs last season',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
          ]),
        ]),
      );
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<double> current, previous;
  final double maxY;
  final String unit;
  const _ChartCard({
    required this.title, required this.current, required this.previous,
    required this.maxY, required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final curSpots = current.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final prevSpots = previous.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgWhite, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder), boxShadow: kShadowSm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
        const SizedBox(height: 14),
        SizedBox(height: 140, child: LineChart(LineChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 20,
              getTitlesWidget: (v, _) => Text(
                'W${v.toInt() + 1}',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey),
              ),
            )),
          ),
          lineBarsData: [
            _line(curSpots, kPrimary),
            _line(prevSpots, kAccentBlue, dashed: true),
          ],
        ))),
      ]),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, {bool dashed = false}) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: dashed ? 2 : 3,
        dashArray: dashed ? [6, 3] : null,
        dotData: const FlDotData(show: false),
        belowBarData: dashed ? BarAreaData(show: false)
            : BarAreaData(show: true, gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      );
}

class _SoilHealthCard extends StatelessWidget {
  final SeasonalComparison data;
  const _SoilHealthCard({required this.data});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBgWhite, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder), boxShadow: kShadowSm,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Soil Health Comparison',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(height: 16),
          _HealthBar(data.current.seasonLabel, data.current.soilHealth / 100, kPrimary),
          const SizedBox(height: 12),
          _HealthBar(data.previous.seasonLabel, data.previous.soilHealth / 100, kAccentBlue),
        ]),
      );
}

class _HealthBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _HealthBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextMid)),
          Text('${(value * 100).round()}%',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value, minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
          ),
        ),
      ]);
}
