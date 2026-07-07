import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/farmer.dart';
import '../services/firestore_service.dart';
import '../services/sensor_service.dart';
import '../services/app_strings.dart';
import '../widgets/premium_widgets.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Farmer?>(
      stream: FirestoreService.instance.farmerStream(),
      builder: (context, farmerSnap) {
        final farmer = farmerSnap.data;
        return StreamBuilder<List<CarbonCredit>>(
          stream: FirestoreService.instance.carbonCreditsStream(),
          builder: (context, credSnap) {
            final credits   = credSnap.data ?? [];
            final eligible  = credits.where((c) => c.status == 'eligible').fold(0.0, (s, c) => s + c.amount);
            final earned    = credits.where((c) => c.status == 'sold').fold(0.0, (s, c) => s + (c.salePrice ?? 0));
            final hour      = DateTime.now().hour;
            final t         = AppStrings.of(context);
            final greeting  = hour < 12 ? t.goodMorning : hour < 17 ? t.goodAfternoon : t.goodEvening;

            return Scaffold(
              body: GradientBackground(
                colors: [kPrimaryLight.withValues(alpha: 0.3), kBgWhite],
                child: SafeArea(
                  child: RefreshIndicator(
                    color: kPrimary,
                    onRefresh: () async => Future.delayed(const Duration(milliseconds: 800)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(children: [
                        const SizedBox(height: 16),
                        _Header(farmer: farmer, greeting: greeting),
                        const SizedBox(height: 20),
                        _LiveHeroBanner(credits: eligible, earned: earned),
                        const SizedBox(height: 20),
                        _Categories(),
                        const SizedBox(height: 20),
                        _InsightCards(),
                        const SizedBox(height: 16),
                        _AlertsSection(),
                        const SizedBox(height: 16),
                        _LiveSoilStatsRow(),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _NdviChart(),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _TipCard(),
                        ),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Farmer? farmer;
  final String greeting;
  const _Header({required this.farmer, required this.greeting});

  void _showSearch(BuildContext context) =>
      showSearch(context: context, delegate: _FarmSearchDelegate());

  void _showNotifications(BuildContext context) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => const _NotificationsSheet(),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showSearch(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: kTextGrey, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                      farmer != null ? '$greeting, ${farmer!.name.split(' ').first}' : AppStrings.of(context).searchFarmData,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey))),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 14),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconBtnWithCounter(icon: Icons.sensors_rounded, press: () => context.go('/sensors')),
          const SizedBox(width: 8),
          IconBtnWithCounter(
              icon: Icons.notifications_outlined,
              numOfItem: 2,
              press: () => _showNotifications(context)),
        ]),
      );
}

// ── Live Hero Banner (sensor stream) ────────────────────────────────────────

class _LiveHeroBanner extends StatefulWidget {
  final double credits, earned;
  const _LiveHeroBanner({required this.credits, required this.earned});
  @override
  State<_LiveHeroBanner> createState() => _LiveHeroBannerState();
}

class _LiveHeroBannerState extends State<_LiveHeroBanner> {
  final _svc = SensorService();
  LiveSensorData? _data;

  @override
  void initState() {
    super.initState();
    _svc.startPolling(intervalSeconds: 30);
    _svc.stream.listen((d) { if (mounted) setState(() => _data = d); });
  }

  @override
  void dispose() { _svc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final score     = _data?.healthScore ?? 0.0;
    final connected = _data?.source == 'hardware';
    final color     = !connected ? kTextGrey : score > 70 ? kPrimary : score > 40 ? kAmber : kRed;
    final t         = AppStrings.of(context);
    final label     = !connected ? t.notConnected : score > 70 ? t.healthy : score > 40 ? t.moderate : t.stressed;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: kShadowMd,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(fit: StackFit.expand, children: [
          CachedNetworkImage(
            imageUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=700&q=80',
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(color: kPrimaryLight),
            errorWidget: (ctx, url, err) => Container(color: kPrimaryLight),
          ),
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xCC000000), Color(0x66000000), Colors.transparent],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  StatusBadge(label, color),
                  if (!connected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 14),
                  ],
                ]),
                const SizedBox(height: 8),
                Text(AppStrings.of(context).cropHealth, style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(connected ? '${score.round()}/100' : '--/100',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 12),
                Row(children: [
                  _BannerStat('₹${widget.earned.toStringAsFixed(0)}', AppStrings.of(context).earned),
                  const SizedBox(width: 20),
                  _BannerStat(widget.credits.toStringAsFixed(1), AppStrings.of(context).credits),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/sell'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: kPrimary, borderRadius: BorderRadius.circular(10)),
                      child: Text(AppStrings.of(context).sell, style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String value, label;
  const _BannerStat(this.value, this.label);
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.plusJakartaSans(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 10)),
      ]);
}

// ── Categories ────────────────────────────────────────────────────────────────

class _Categories extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final cats = [
      (Icons.satellite_alt_rounded, t.satellite,    '/scan',       kPrimary),
      (Icons.sensors_rounded,       t.sensors,      '/sensors',    kAccentBlue),
      (Icons.grass_rounded,         t.fertilizerCat,'/fertilizer', kAccentGold),
      (Icons.cloud_outlined,        t.climate,      '/climate',    const Color(0xFF8B5CF6)),
      (Icons.camera_alt_rounded,    t.cameraAnalysis,'/camera',    const Color(0xFFEC4899)),
      (Icons.bar_chart_rounded,     t.reports,      '/reports',    const Color(0xFF10B981)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: cats.map((c) => _CatTile(c.$1, c.$2, c.$3, c.$4, context)).toList(),
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  final IconData icon;
  final String label, route;
  final Color color;
  final BuildContext ctx;
  const _CatTile(this.icon, this.label, this.route, this.color, this.ctx);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => ctx.go(route),
        child: Column(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 5),
          Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w600, color: kTextMid)),
        ]),
      );
}

// ── Insight Cards (horizontal scroll) ────────────────────────────────────────

class _InsightCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final cards = [
      _InsightData(t.carbonReport,   '59.3 t C/ha',   'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=90', '/carbon'),
      _InsightData(t.fertilizerPlan, 'N deficit 44%', 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800&q=90', '/fertilizer'),
      _InsightData(t.climateRisk,    '30% Moderate',  'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&q=90', '/climate'),
    ];
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: cards.length,
        itemBuilder: (context, idx) => _InsightCard(card: cards[idx]),
      ),
    );
  }
}

class _InsightData {
  final String title, value, imageUrl, route;
  const _InsightData(this.title, this.value, this.imageUrl, this.route);
}

class _InsightCard extends StatelessWidget {
  final _InsightData card;
  const _InsightCard({required this.card});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go(card.route),
        child: Container(
          width: 200, height: 120,
          margin: const EdgeInsets.only(right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(fit: StackFit.expand, children: [
              CachedNetworkImage(
                imageUrl: card.imageUrl, fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(color: kPrimaryLight),
                errorWidget: (ctx, url, err) => Container(
                    color: kPrimaryLight,
                    child: const Icon(Icons.eco_rounded, color: kPrimary, size: 40)),
              ),
              Container(decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC000000), Colors.transparent],
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                ),
              )),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(card.title, style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(card.value, style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}

// ── Alerts ────────────────────────────────────────────────────────────────────

class _AlertsSection extends StatefulWidget {
  @override
  State<_AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<_AlertsSection> {
  final _svc = SensorService();
  final _dismissed = <int>{};
  List<SensorAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _svc.startPolling(intervalSeconds: 30);
    _svc.stream.listen((d) { if (mounted) setState(() => _alerts = d.alerts); });
  }

  @override
  void dispose() { _svc.dispose(); super.dispose(); }

  Color _color(AlertLevel l) =>
      l == AlertLevel.high ? kRed : l == AlertLevel.medium ? kAmber : kPrimary;

  @override
  Widget build(BuildContext context) {
    final alerts = _alerts.asMap().entries
        .where((e) => !_dismissed.contains(e.key))
        .toList();
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(AppStrings.of(context).alerts, style: GoogleFonts.plusJakartaSans(
              fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(width: 8),
          StatusBadge('${alerts.length}', kRed),
        ]),
        const SizedBox(height: 10),
        ...alerts.map((entry) {
          final a     = entry.value;
          final color = _color(a.level);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.warning_amber_rounded, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.level.name.toUpperCase(), style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: color, letterSpacing: 0.5)),
                Text(a.message, style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: kTextDark, fontWeight: FontWeight.w500)),
              ])),
              GestureDetector(
                onTap: () => setState(() => _dismissed.add(entry.key)),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: kBgCard, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close_rounded, color: kTextGrey, size: 14)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Live Soil Stats Row ───────────────────────────────────────────────────────

class _LiveSoilStatsRow extends StatefulWidget {
  @override
  State<_LiveSoilStatsRow> createState() => _LiveSoilStatsRowState();
}

class _LiveSoilStatsRowState extends State<_LiveSoilStatsRow> {
  final _svc = SensorService();
  LiveSensorData? _data;

  @override
  void initState() {
    super.initState();
    _svc.startPolling(intervalSeconds: 30);
    _svc.stream.listen((d) { if (mounted) setState(() => _data = d); });
  }

  @override
  void dispose() { _svc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final connected = _data?.source == 'hardware';
    final n  = connected ? _data!.n  : 0.0;
    final ph = connected ? _data!.ph : 0.0;
    final ec = connected ? _data!.ec : 0.0;
    final m  = connected ? _data!.moisture : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!connected)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.wifi_off_rounded, color: kTextGrey, size: 14),
                const SizedBox(width: 6),
                Text(AppStrings.of(context).sensorNotConnected, style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: kTextGrey)),
              ]),
            ),
          Row(children: [
            _SoilBox('N',   '${n.round()}',              'ppm', kPrimary),
            const SizedBox(width: 10),
            _SoilBox('pH',  ph.toStringAsFixed(1),       '',    kAccentBlue),
            const SizedBox(width: 10),
            _SoilBox('EC',  ec.toStringAsFixed(1),       'mS',  kAccentGold),
            const SizedBox(width: 10),
            _SoilBox('H₂O', '${m.round()}%',             '',    const Color(0xFF8B5CF6)),
          ]),
        ],
      ),
    );
  }
}

class _SoilBox extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _SoilBox(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(children: [
            Text(value, style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            if (unit.isNotEmpty) ...[
              Text(unit, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTextGrey)),
            ],
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w600, color: kTextGrey)),
          ]),
        ),
      );
}

// ── NDVI Chart ────────────────────────────────────────────────────────────────

class _NdviChart extends StatefulWidget {
  @override
  State<_NdviChart> createState() => _NdviChartState();
}

class _NdviChartState extends State<_NdviChart> {
  final _svc = SensorService();
  double _ndvi = 0;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _svc.startPolling(intervalSeconds: 30);
    _svc.stream.listen((d) {
      if (mounted) {
        setState(() {
          _ndvi      = d.ndviProxy;
          _connected = d.source == 'hardware';
        });
      }
    });
  }

  @override
  void dispose() { _svc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(7, (i) =>
        FlSpot(i.toDouble(), _connected ? _ndvi * (0.5 + i * 0.08) : 0));

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_connected ? 'NDVI: ${_ndvi.toStringAsFixed(2)}' : 'NDVI: --',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
          if (!_connected) ...[
            Row(children: [
              const Icon(Icons.wifi_off_rounded, color: kTextGrey, size: 14),
              const SizedBox(width: 4),
              Text(AppStrings.of(context).noSensorData, style: GoogleFonts.plusJakartaSans(
                  color: kTextGrey, fontSize: 12)),
            ]),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.sensors_rounded, color: kPrimary, size: 14),
                const SizedBox(width: 4),
                Text(AppStrings.of(context).live, style: GoogleFonts.plusJakartaSans(
                    color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: LineChart(LineChartData(
            minY: 0, maxY: 1.0,
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: kBorder, strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots, isCurved: true, curveSmoothness: 0.4,
                color: _connected ? kPrimary : kTextGrey, barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (s, p, d, idx) => FlDotCirclePainter(
                    radius: idx == spots.length - 1 ? 5 : 0,
                    color: _connected ? kPrimary : kTextGrey,
                    strokeWidth: 2.5, strokeColor: kBgWhite)),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      (_connected ? kPrimary : kTextGrey).withValues(alpha: 0.15),
                      (_connected ? kPrimary : kTextGrey).withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              ),
            ],
          )),
        ),
      ]),
    );
  }
}

// ── Tip Card ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          SizedBox(
            height: 110,
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&q=90',
              fit: BoxFit.cover, width: double.infinity,
              placeholder: (ctx, url) => Container(color: kPrimaryLight),
              errorWidget: (ctx, url, err) => Container(color: kPrimaryLight),
            ),
          ),
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimary.withValues(alpha: 0.85),
                  kPrimary.withValues(alpha: 0.5)
                ],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.of(context).aiTipOfTheDay, style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white60, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                        'SCI Index 68/100 — add compost to boost organic matter by 15%',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: Colors.white, height: 1.35)),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      );
}

// ── Search Delegate ───────────────────────────────────────────────────────────

class _FarmSearchDelegate extends SearchDelegate<String> {
  static const _suggestions = [
    'Carbon Report', 'Fertilizer Plan', 'NDVI Trend',
    'Soil Moisture', 'Climate Risk', 'Sell Credits', 'Sensor Data',
  ];

  @override
  String get searchFieldLabel => 'Search farm data…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = query.isEmpty
        ? _suggestions
        : _suggestions
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, idx) => ListTile(
        leading: const Icon(Icons.search_rounded, color: kPrimary),
        title: Text(results[idx],
            style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        onTap: () => close(context, results[idx]),
      ),
    );
  }
}

// ── Notifications Sheet ───────────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  static const _notifData = [
    (Icons.eco_rounded,           kPrimary,    'Carbon credits ready',   'You have 12.5 t eligible for sale'),
    (Icons.warning_amber_rounded, kAccentGold, 'Low soil moisture',      'Field A moisture dropped to 28%'),
    (Icons.cloud_outlined,        kAccentBlue, 'Rain forecast',          'Heavy rain expected in 2 days'),
  ];

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.of(context).notifications, style: GoogleFonts.plusJakartaSans(
                    fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
                StatusBadge('${_notifData.length}', kPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._notifData.map((n) => ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: n.$2.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(n.$1, color: n.$2, size: 20),
                ),
                title: Text(n.$3, style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
                subtitle: Text(n.$4, style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: kTextGrey)),
              )),
          const SizedBox(height: 16),
        ],
      );
}
