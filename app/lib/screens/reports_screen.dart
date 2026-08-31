import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/app_strings.dart';
import '../services/auth_service.dart';
import '../services/sensor_service.dart';
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
    _tabs = TabController(length: 3, vsync: this);
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
        title: Text(AppStrings.of(context).reportsTitle),
        automaticallyImplyLeading: false,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: AppStrings.of(context).carbon),
            Tab(text: AppStrings.of(context).credits),
            Tab(text: AppStrings.of(context).navReports),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _CarbonTrendTab(),
          _CreditsTab(),
          _SeasonalTab(),
        ],
      ),
    );
  }
}

// ── Shared fetch helper ───────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> _fetchHistory() async {
  try {
    final res = await http.get(
      Uri.parse('$kApiBase/sensor/history?limit=40'),
      headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
    ).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
  } catch (_) {}
  return [];
}

// ── Tab 1: Carbon Trend ───────────────────────────────────────────────────────

class _CarbonTrendTab extends StatefulWidget {
  const _CarbonTrendTab();
  @override
  State<_CarbonTrendTab> createState() => _CarbonTrendTabState();
}

class _CarbonTrendTabState extends State<_CarbonTrendTab> {
  List<Map<String, dynamic>> _history = [];
  LiveSensorData? _live;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = SensorService();
    final results = await Future.wait([_fetchHistory(), svc.fetchOnce()]);
    svc.dispose();
    if (!mounted) return;
    setState(() {
      _history = results[0] as List<Map<String, dynamic>>;
      _live    = results[1] as LiveSensorData;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));

    final ndviSpots = _history.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['ndvi_proxy'] as num).toDouble()))
        .toList();
    final co2Spots = _history.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['co2_equivalent'] as num).toDouble()))
        .toList();

    final avgNdvi = _history.isEmpty ? 0.0
        : _history.map((e) => (e['ndvi_proxy'] as num).toDouble()).reduce((a, b) => a + b) / _history.length;
    final totalCo2 = _live?.co2Equivalent ?? 0.0;

    return RefreshIndicator(
      onRefresh: () async { setState(() => _loading = true); await _load(); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _StatBox('Avg NDVI',   avgNdvi.toStringAsFixed(3),          kGreen),
            const SizedBox(width: 8),
            _StatBox('CO₂e',       '${totalCo2.toStringAsFixed(1)} t',  kAmber),
            const SizedBox(width: 8),
            _StatBox('Readings',   '${_history.length}',                Colors.blue),
          ]),
          const SizedBox(height: 16),
          if (ndviSpots.length > 1) ...[
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NDVI Trend', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(height: 12),
                SizedBox(height: 120, child: _buildChart(ndviSpots, kGreen, maxY: 1.0)),
              ],
            ))),
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CO₂e History (tons/ha)', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(height: 12),
                SizedBox(height: 120, child: _buildChart(co2Spots, kAmber)),
              ],
            ))),
          ] else
            const Card(child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Not enough history yet. Check back after more sensor readings.',
                  textAlign: TextAlign.center, style: TextStyle(color: kTextGrey))),
            )),
          if (_live != null) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Latest Sensor Recommendations',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(height: 8),
                if (_live!.alerts.isEmpty)
                  const Text('All parameters optimal 🌱', style: TextStyle(fontSize: 13, color: kPrimary))
                else
                  ..._live!.alerts.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: a.level == AlertLevel.high ? kRed : kAmber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a.message, style: const TextStyle(fontSize: 13))),
                    ]),
                  )),
              ],
            ))),
          ],
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  LineChart _buildChart(List<FlSpot> spots, Color color, {double? maxY}) =>
      LineChart(LineChartData(
        minY: 0, maxY: maxY,
        gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [LineChartBarData(
          spots: spots, isCurved: true, color: color, barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
        )],
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
          child: Column(children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: kTextGrey)),
          ]),
        ),
      );
}

// ── Tab 2: Credits ────────────────────────────────────────────────────────────

class _CreditsTab extends StatefulWidget {
  const _CreditsTab();
  @override
  State<_CreditsTab> createState() => _CreditsTabState();
}

class _CreditsTabState extends State<_CreditsTab> {
  List<Map<String, dynamic>> _credits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('$kApiBase/carbon-credits'),
        headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _credits = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));

    final sold     = _credits.where((c) => c['status'] == 'sold').toList();
    final eligible = _credits.where((c) => c['status'] == 'eligible').toList();
    final earned   = sold.fold(0.0, (s, c) => s + ((c['sale_price'] as num?)?.toDouble() ?? 0));
    final fmt      = DateFormat('dd MMM yyyy');

    return RefreshIndicator(
      onRefresh: () async { setState(() => _loading = true); await _load(); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            color: const Color(0xFFF1F8E9),
            child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              const Icon(Icons.account_balance_wallet, color: kGreen, size: 36),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Earnings', style: TextStyle(fontSize: 12, color: kTextGrey)),
                Text('₹${earned.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kGreen)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${sold.length} sold',     style: const TextStyle(fontSize: 12, color: kTextGrey)),
                Text('${eligible.length} eligible', style: const TextStyle(fontSize: 12, color: kAmber)),
              ]),
            ])),
          ),
          const SizedBox(height: 16),
          if (_credits.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No carbon credits yet. Run a satellite analysis to generate credits.',
                  textAlign: TextAlign.center, style: TextStyle(color: kTextGrey))),
            )),
          if (eligible.isNotEmpty) ...[
            const Text('Eligible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark)),
            const SizedBox(height: 8),
            ...eligible.map((c) => _CreditRow(credit: c, fmt: fmt)),
            const SizedBox(height: 16),
          ],
          if (sold.isNotEmpty) ...[
            const Text('Sold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark)),
            const SizedBox(height: 8),
            ...sold.map((c) => _CreditRow(credit: c, fmt: fmt)),
          ],
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final Map<String, dynamic> credit;
  final DateFormat fmt;
  const _CreditRow({required this.credit, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isSold  = credit['status'] == 'sold';
    final color   = isSold ? kGreenSoft : kAmber;
    final amount  = (credit['amount'] as num).toDouble();
    final price   = (credit['sale_price'] as num?)?.toDouble();
    final soldRaw = credit['sold_date'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(isSold ? Icons.check : Icons.eco, color: color, size: 20),
        ),
        title: Text('${amount.toStringAsFixed(3)} tons CO₂e',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          isSold && soldRaw != null
              ? 'Sold on ${fmt.format(DateTime.parse(soldRaw))}'
              : 'Eligible for sale',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSold && price != null
            ? Text('₹${price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: kGreenSoft, fontSize: 14))
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kAmber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Text('ELIGIBLE', style: TextStyle(fontSize: 10, color: kAmber, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }
}

// ── Tab 3: Seasonal ───────────────────────────────────────────────────────────

class _SeasonalTab extends StatelessWidget {
  const _SeasonalTab();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.compare_arrows_rounded, color: kPrimary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.of(context).seasonalComparison,
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
