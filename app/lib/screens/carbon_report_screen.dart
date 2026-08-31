import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/app_strings.dart';
import '../services/auth_service.dart';
import '../services/carbon_market_service.dart';
import '../services/pdf_service.dart';
import '../services/satellite_service.dart';
import '../services/sensor_service.dart';
import '../theme.dart';

Future<List<Map<String, dynamic>>> _fetchSensorHistory() async {
  try {
    final res = await http.get(
      Uri.parse('$kApiBase/sensor/history?limit=50'),
      headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
    ).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
  } catch (_) {}
  return [];
}

Future<Map<String, dynamic>?> _fetchCarbonDelta() async {
  try {
    final res = await http.get(
      Uri.parse('$kApiBase/carbon/delta?limit=50'),
      headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
    ).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
  } catch (_) {}
  return null;
}

class CarbonReportScreen extends StatefulWidget {
  const CarbonReportScreen({super.key});
  @override
  State<CarbonReportScreen> createState() => _CarbonReportScreenState();
}

class _CarbonReportScreenState extends State<CarbonReportScreen> {
  LiveSensorData? _live;
  SatelliteResult? _satellite;
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _delta;
  CarbonMarketPrice? _market;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = SensorService();
    final results = await Future.wait([
      svc.fetchOnce(),
      _fetchSensorHistory(),
      _fetchCarbonDelta(),
      SatelliteService().loadCache(),
      CarbonMarketService.instance.fetchPrice(),
    ]);
    svc.dispose();
    if (!mounted) return;
    setState(() {
      _live      = results[0] as LiveSensorData;
      _history   = results[1] as List<Map<String, dynamic>>;
      _delta     = results[2] as Map<String, dynamic>?;
      _satellite = results[3] as SatelliteResult?;
      _market    = results[4] as CarbonMarketPrice;
      _loading   = false;
    });
  }

  double get _current => _satellite?.carbon ?? _live!.carbon;
  double get _co2e    => _satellite?.co2e    ?? _live!.co2Equivalent;

  /// True sequestration delta from backend /carbon/delta.
  /// Falls back to history-derived delta, then snapshot.
  double get _credits {
    if (_delta != null) {
      return (_delta!['credits'] as num).toDouble();
    }
    if (_history.length >= 2) {
      final oldest = (_history.first['carbon'] as num).toDouble();
      final newest = (_history.last['carbon']  as num).toDouble();
      return (newest - oldest).clamp(0.0, double.infinity);
    }
    return _satellite?.carbonCredits ?? _live!.co2Equivalent;
  }

  /// CO₂e of the sequestered delta (not current stock snapshot).
  double get _deltaCo2e {
    if (_delta != null) return (_delta!['delta_co2e'] as num).toDouble();
    return _credits; // credits already in CO₂e
  }

  String get _periodLabel {
    if (_delta != null) {
      final days = (_delta!['period_days'] as num).toInt();
      return days > 0 ? 'Last $days days' : 'Current period';
    }
    if (_history.length >= 2) {
      final first = DateTime.tryParse(_history.first['timestamp'] as String? ?? '');
      final last  = DateTime.tryParse(_history.last['timestamp']  as String? ?? '');
      if (first != null && last != null) {
        final days = last.difference(first).inDays;
        return days > 0 ? 'Last $days days' : 'Current period';
      }
    }
    return 'Current snapshot';
  }

  /// Payout = credits × live market price × 90% farmer share
  double get _payout  => _market != null
      ? _market!.farmerPayout(_credits)
      : _credits * 800 * 0.90;

  Future<void> _downloadCertificate() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_live == null) return;
    try {
      messenger.showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).generatingCert),
          duration: const Duration(seconds: 2)));
      final bytes = await PdfService.instance.generateCertificate(
        farmerName: AuthService.instance.name ?? 'Farmer',
        farmName: 'My Farm',
        location: _satellite != null
            ? (_satellite!.placeName.isNotEmpty
                ? _satellite!.placeName
                : '${_satellite!.lat.toStringAsFixed(4)}, ${_satellite!.lng.toStringAsFixed(4)}')
            : 'Tanjavur, TN',
        carbonCredits: _credits,
        co2eReduced: _co2e,
        transactionId:
            'CARBON-TN-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 100000}',
        issuedDate: DateTime.now(),
      );
      await Printing.sharePdf(bytes: bytes, filename: 'carbon-certificate.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBgPage,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    final live       = _live!;
    final sat        = _satellite;
    final market     = _market!;
    final current    = _current;
    final co2e       = _co2e;          // current stock CO₂e (snapshot)
    final deltaCo2e  = _deltaCo2e;     // sequestered CO₂e (delta) — used for credits & impact
    final credits    = _credits;
    final payout     = _payout;
    final baseline   = _delta != null
        ? (_delta!['baseline_carbon'] as num).toDouble()
        : _history.length >= 2
            ? (_history.first['carbon'] as num).toDouble()
            : 0.0;
    final additional = (current - baseline).clamp(0.0, double.infinity);
    final stability  = live.healthScore.clamp(0.0, 100.0);
    final microbial  = (live.healthScore * 0.92).clamp(0.0, 100.0);
    final areaLabel  = sat != null
        ? sat.placeName.isNotEmpty
            ? sat.placeName
            : '${sat.lat.toStringAsFixed(4)}, ${sat.lng.toStringAsFixed(4)}'
        : 'Live Sensor';
    final dateLabel  = sat != null
        ? DateFormat('dd MMM yyyy').format(sat.satelliteDate)
        : DateFormat('MMM yyyy').format(DateTime.now());

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
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: kTextDark, size: 16),
              onPressed: () => context.go('/dashboard'),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.eco_rounded, color: kPrimary, size: 14),
              const SizedBox(width: 4),
              Text('Carbon',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPrimary)),
            ]),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          SizedBox(
            height: 260,
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=700&q=80',
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (ctx, url) => Container(color: kPrimaryLight),
              errorWidget: (ctx, url, err) => Container(
                  color: kPrimaryLight,
                  child: const Icon(Icons.eco_rounded,
                      color: kPrimary, size: 80)),
            ),
          ),
          TopRoundedContainer(
            color: kBgWhite,
            child: Column(children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        StatusBadge(AppStrings.of(context).verified, kPrimary),
                        const Spacer(),
                        Text(dateLabel,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: kTextGrey)),
                      ]),
                      const SizedBox(height: 10),
                      Text(AppStrings.of(context).carbonReport,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kTextDark)),
                      const SizedBox(height: 4),
                      Text(areaLabel,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: kTextGrey)),
                      const SizedBox(height: 16),
                      Row(children: [
                        _BigStat(current.toStringAsFixed(2), 'tons C/ha',
                            kPrimary),
                        Container(
                            width: 1,
                            height: 44,
                            color: kBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 16)),
                        _BigStat(co2e.toStringAsFixed(2), 'tons CO₂e/ha',
                            kGreenSoft),
                        Container(
                            width: 1,
                            height: 44,
                            color: kBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 16)),
                        _BigStat('${stability.round()}%', 'Health',
                            kAccentBlue),
                      ]),
                      const SizedBox(height: 20),
                    ]),
              ),
              TopRoundedContainer(
                color: kBgPage,
                child: Column(children: [
                  const SizedBox(height: 20),

                  // ── Live Market Price Banner ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MarketPriceBanner(market: market),
                  ),
                  const SizedBox(height: 16),

                  // ── Carbon Credits Box ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      glow: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            AppStrings.of(context)
                                                .carbonCreditsBox,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: kTextDark)),
                                        Text(_periodLabel,
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                color: kTextGrey)),
                                      ]),
                                  StatusBadge(
                                      AppStrings.of(context).eligible,
                                      kAccentGold),
                                ]),
                            const SizedBox(height: 16),
                            _CreditLine(AppStrings.of(context).baseline,
                                '${baseline.toStringAsFixed(3)} t C',
                                kTextGrey),
                            _CreditLine(AppStrings.of(context).current,
                                '${current.toStringAsFixed(3)} t C',
                                kTextMid),
                            _CreditLine(AppStrings.of(context).additional,
                                '${additional.toStringAsFixed(3)} t C',
                                kPrimary),
                            _CreditLine('Credits',
                                '${credits.toStringAsFixed(3)} tons CO₂e',
                                kAccentGold),
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: kBorder)),

                            // Live price row
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: market.source == 'floor'
                                            ? kAmber
                                            : kPrimary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (market.source == 'floor'
                                                    ? kAmber
                                                    : kPrimary)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 4,
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                        market.source == 'floor'
                                            ? 'ICM Floor Price'
                                            : market.source == 'cache'
                                                ? 'Last Market Price'
                                                : 'Live Market Price',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, color: kTextGrey)),
                                  ]),
                                  Text(
                                    '₹${market.priceInr.toStringAsFixed(0)} / credit',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kAccentGold),
                                  ),
                                ]),
                            const SizedBox(height: 4),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      '\$${market.priceUsd.toStringAsFixed(2)}/tCO₂e  ·  1\$ = ₹${market.usdToInr.toStringAsFixed(1)}',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11, color: kTextGrey)),
                                  Text('90% farmer share',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11, color: kTextGrey)),
                                ]),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color: kPrimaryLight,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                '${AppStrings.of(context).youCanEarn}  ₹${NumberFormat('#,##,###').format(payout.round())}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: kPrimary),
                              ),
                            ),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Sensor History Chart ──────────────────────────────
                  if (_history.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        AppStrings.of(context).fiveYearTrend,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: kTextDark)),
                                    Row(children: [
                                      const Icon(Icons.sensors_rounded,
                                          color: kPrimary, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Live',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: kPrimary)),
                                    ]),
                                  ]),
                              const SizedBox(height: 16),
                              SizedBox(
                                  height: 130,
                                  child: LineChart(LineChartData(
                                    gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (_) =>
                                            const FlLine(
                                                color: kBorder,
                                                strokeWidth: 1)),
                                    borderData: FlBorderData(show: false),
                                    titlesData: const FlTitlesData(
                                      leftTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _history
                                            .asMap()
                                            .entries
                                            .map((e) => FlSpot(
                                                e.key.toDouble(),
                                                (e.value['carbon'] as num)
                                                    .toDouble()))
                                            .toList(),
                                        isCurved: true,
                                        color: kPrimary,
                                        barWidth: 3,
                                        dotData: FlDotData(
                                            show: true,
                                            getDotPainter: (a, b, c, d) =>
                                                FlDotCirclePainter(
                                                    radius: 5,
                                                    color: kPrimary,
                                                    strokeWidth: 2.5,
                                                    strokeColor: kBgWhite)),
                                        belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                kPrimary.withValues(
                                                    alpha: 0.15),
                                                kPrimary.withValues(alpha: 0.0)
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            )),
                                      )
                                    ],
                                  ))),
                            ]),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Carbon Stability ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.of(context).carbonStability,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: kTextDark)),
                            const SizedBox(height: 16),
                            _BarRow(AppStrings.of(context).permanence,
                                stability / 100, '${stability.round()}%',
                                kPrimary),
                            const SizedBox(height: 12),
                            _BarRow(AppStrings.of(context).microbialHealth,
                                microbial / 100, '${microbial.round()}%',
                                kAccentBlue),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Environmental Impact ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimary.withValues(alpha: 0.08),
                            kAccentBlue.withValues(alpha: 0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.of(context).envImpact,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: kTextDark)),
                            const SizedBox(height: 14),
                            Row(children: [
                              _ImpactTile(
                                  '🚗',
                                  '${(deltaCo2e / 4.6).clamp(0, 9999).round()}',
                                  'Cars off road\nper year',
                                  kAccentBlue),
                              const SizedBox(width: 10),
                              _ImpactTile(
                                  '🌳',
                                  '${(deltaCo2e * 45.6).clamp(0, 999999).round()}',
                                  'Trees planted\nequivalent',
                                  kPrimary),
                            ]),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: TopRoundedContainer(
        color: kBgWhite,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: _downloadCertificate,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(AppStrings.of(context).certificate),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () => context.go('/sell'),
                icon: const Icon(Icons.sell_rounded, size: 18),
                label: Text(AppStrings.of(context).sellCarbonCredits),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Market Price Banner ───────────────────────────────────────────────────────

class _MarketPriceBanner extends StatelessWidget {
  final CarbonMarketPrice market;
  const _MarketPriceBanner({required this.market});

  @override
  Widget build(BuildContext context) {
    final isLive  = market.source == 'ember' || market.source == 'worldbank';
    final isFloor = market.source == 'floor';
    final color   = isFloor ? kAmber : kPrimary;
    final label   = isFloor
        ? 'ICM Floor Price'
        : isLive
            ? 'Live Market Price'
            : 'Last Known Price';
    final sourceLabel = market.source == 'ember'
        ? 'Ember Climate'
        : market.source == 'worldbank'
            ? 'World Bank'
            : market.source == 'cache'
                ? 'Cached'
                : 'ICM BEE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isLive ? Icons.show_chart_rounded : Icons.history_rounded,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.5)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(sourceLabel,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(
              '\$${market.priceUsd.toStringAsFixed(2)}/tCO₂e  ·  1\$ = ₹${market.usdToInr.toStringAsFixed(1)}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: kTextGrey),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '₹${market.priceInr.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          Text('per credit',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: kTextGrey)),
        ]),
      ]),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _BigStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: kTextGrey)),
        ]),
      );
}

class _CreditLine extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CreditLine(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: kTextGrey)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}

class _BarRow extends StatelessWidget {
  final String label, text;
  final double value;
  final Color color;
  const _BarRow(this.label, this.value, this.text, this.color);
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: kTextMid)),
          Text(text,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color),
        ),
      ]);
}

class _ImpactTile extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _ImpactTile(this.emoji, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kBgWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: kTextGrey, height: 1.4)),
          ]),
        ),
      );
}
