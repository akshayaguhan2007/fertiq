import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/farmer.dart';
import '../services/mock_data.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & History'),
        automaticallyImplyLeading: false,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Analyses'),
            Tab(text: 'Carbon'),
            Tab(text: 'Credits'),
            Tab(text: 'Seasonal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _AnalysesTab(),
          _CarbonTrendTab(),
          _CreditsTab(),
          _SeasonalTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Analysis History ───────────────────────────────────────────────────

class _AnalysesTab extends StatelessWidget {
  const _AnalysesTab();

  @override
  Widget build(BuildContext context) {
    final analyses = [MockData.analysis];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      itemBuilder: (_, i) {
        final a     = analyses[i];
        final score = a.healthScore;
        final color = score > 70 ? kGreenSoft : score > 40 ? kAmber : kRed;
        final fmt   = DateFormat('dd MMM yyyy, hh:mm a');
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.12)),
                  child: Center(
                    child: Text('${score.round()}%',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            color: color, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.cropType.toUpperCase()} · ${a.growthStage}',
                        style: const TextStyle(fontWeight: FontWeight.w600,
                            fontSize: 13, color: kTextDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NDVI ${a.ndvi.toStringAsFixed(3)}  ·  '
                        'CO₂e ${a.carbon.co2Equivalent.toStringAsFixed(2)} t',
                        style: const TextStyle(fontSize: 12, color: kTextGrey),
                      ),
                      const SizedBox(height: 2),
                      Text(fmt.format(a.timestamp),
                          style: const TextStyle(fontSize: 11, color: kTextGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 2: Carbon Trend Chart ─────────────────────────────────────────────────

class _CarbonTrendTab extends StatelessWidget {
  const _CarbonTrendTab();

  @override
  Widget build(BuildContext context) {
    final ndviSpots = MockData.ndviHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final co2Spots = MockData.carbonHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.carbon))
        .toList();

    final avgNdvi = MockData.ndviHistory.reduce((a, b) => a + b) /
        MockData.ndviHistory.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatBox('Avg NDVI', avgNdvi.toStringAsFixed(3), kGreen),
              const SizedBox(width: 8),
              _StatBox('Total CO₂e', '${MockData.co2eAdditional.toStringAsFixed(1)} t', kAmber),
              const SizedBox(width: 8),
              _StatBox('Readings', '${MockData.ndviHistory.length}', Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NDVI Trend',
                      style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                  const SizedBox(height: 12),
                  SizedBox(height: 120, child: _buildChart(ndviSpots, kGreen, maxY: 1.0)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Carbon History (tons C/ha)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                  const SizedBox(height: 12),
                  SizedBox(height: 120, child: _buildChart(co2Spots, kAmber)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latest Recommendations',
                      style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                  const SizedBox(height: 8),
                  ...MockData.analysis.recommendations.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates,
                                size: 16, color: kGreen),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r,
                                style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  LineChart _buildChart(List<FlSpot> spots, Color color, {double? maxY}) =>
      LineChart(LineChartData(
        minY: 0, maxY: maxY,
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, color: color, barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true,
                color: color.withValues(alpha: 0.1)),
          ),
        ],
      ));
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: kTextGrey)),
            ],
          ),
        ),
      );
}

// ── Tab 3: Credits History ────────────────────────────────────────────────────

class _CreditsTab extends StatelessWidget {
  const _CreditsTab();

  @override
  Widget build(BuildContext context) {
    final credits  = MockData.credits;
    final sold     = credits.where((c) => c.status == 'sold').toList();
    final eligible = credits.where((c) => c.status == 'eligible').toList();
    final earned   = sold.fold(0.0, (s, c) => s + (c.salePrice ?? 0));
    final fmt      = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFFF1F8E9),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: kGreen, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Earnings',
                          style: TextStyle(fontSize: 12, color: kTextGrey)),
                      Text('₹${earned.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24,
                              fontWeight: FontWeight.bold, color: kGreen)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${sold.length} sold',
                          style: const TextStyle(fontSize: 12, color: kTextGrey)),
                      Text('${eligible.length} eligible',
                          style: const TextStyle(fontSize: 12, color: kAmber)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (eligible.isNotEmpty) ...[
            const Text('Eligible',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: kTextDark)),
            const SizedBox(height: 8),
            ...eligible.map((c) => _CreditRow(credit: c, fmt: fmt)),
            const SizedBox(height: 16),
          ],
          if (sold.isNotEmpty) ...[
            const Text('Sold',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: kTextDark)),
            const SizedBox(height: 8),
            ...sold.map((c) => _CreditRow(credit: c, fmt: fmt)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final CarbonCredit credit;
  final DateFormat fmt;
  const _CreditRow({required this.credit, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isSold = credit.status == 'sold';
    final color  = isSold ? kGreenSoft : kAmber;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(isSold ? Icons.check : Icons.eco, color: color, size: 20),
        ),
        title: Text('${credit.amount.toStringAsFixed(3)} tons CO₂e',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          isSold && credit.soldDate != null
              ? 'Sold on ${fmt.format(credit.soldDate!)}'
              : 'Eligible for sale',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSold && credit.salePrice != null
            ? Text('₹${credit.salePrice!.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: kGreenSoft, fontSize: 14))
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ELIGIBLE',
                    style: TextStyle(fontSize: 10, color: kAmber,
                        fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }
}

// ── Tab 4: Seasonal Comparison entry ─────────────────────────────────────────

class _SeasonalTab extends StatelessWidget {
  const _SeasonalTab();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.compare_arrows_rounded, color: kPrimary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Seasonal Comparison',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 8),
            Text('Compare this season vs last season\nfor NDVI, Yield, Carbon & Soil Health.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey, height: 1.6)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/seasonal'),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text('View Comparison'),
            ),
          ]),
        ),
      );
}
