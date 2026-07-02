import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../services/satellite_service.dart';
import '../services/gemini_service.dart';
import '../services/mock_data.dart';
import '../theme.dart';

const _crops  = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane', 'Soybean'];
const _stages = ['Vegetative', 'Reproductive', 'Maturity'];

// Default: Tanjavur farm
const _kDefaultLat = 10.7867;
const _kDefaultLng = 79.1378;

class SatelliteAnalysisScreen extends StatefulWidget {
  const SatelliteAnalysisScreen({super.key});
  @override
  State<SatelliteAnalysisScreen> createState() => _SatelliteAnalysisScreenState();
}

class _SatelliteAnalysisScreenState extends State<SatelliteAnalysisScreen> {
  final _satellite   = SatelliteService();
  final _gemini      = GeminiService();
  final _mapCtrl     = MapController();

  LatLng _pinned     = const LatLng(_kDefaultLat, _kDefaultLng);
  bool   _locating   = false;
  String _crop       = 'Rice';
  String _stage      = 'Reproductive';
  DateTime _from     = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to       = DateTime.now();

  bool   _loading    = false;
  String _loadStep   = '';
  SatelliteResult?        _result;
  GeminiRecommendations?  _recs;

  // ── Live location ──────────────────────────────────────────────────────────
  Future<void> _goToLiveLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Location permission denied. Enable it in Settings.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _pinned = loc);
      _mapCtrl.move(loc, 15);
    } catch (e) {
      _showSnack('Could not get location. Using default.');
    } finally {
      setState(() => _locating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
    );
  }

  // ── Fetch satellite data ───────────────────────────────────────────────────
  Future<void> _fetchData() async {
    setState(() {
      _loading  = true;
      _result   = null;
      _recs     = null;
      _loadStep = 'Fetching Sentinel-2 data…';
    });

    final result = await _satellite.fetchNDVI(
      lat: _pinned.latitude,
      lng: _pinned.longitude,
      radiusMeters: 500,
      startDate: DateFormat('yyyy-MM-dd').format(_from),
      endDate:   DateFormat('yyyy-MM-dd').format(_to),
    );

    setState(() => _loadStep = 'Running AI analysis…');

    final soil = MockData.soilReading;
    final recs = await _gemini.getRecommendations(
      cropType: _crop, growthStage: _stage,
      ndvi: result.ndvi, biomass: result.biomass, carbon: result.carbon,
      soilN: soil.n, soilP: soil.p, soilK: soil.k,
      district: MockData.farmer.district,
      weatherSummary:
          '${MockData.forecast.first.temp}°C, rain: ${MockData.forecast.first.rain}mm',
    );

    setState(() { _loading = false; _result = result; _recs = recs; });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isFrom ? _from = picked : _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Satellite Analysis',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.satellite_alt_rounded, color: kPrimary, size: 14),
              const SizedBox(width: 4),
              Text('Sentinel-2',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPrimary)),
            ]),
          ),
        ],
      ),
      body: _result != null
          ? _ResultView(
              result: _result!,
              recs: _recs,
              crop: _crop,
              stage: _stage,
              pinned: _pinned,
              onRescan: () => setState(() { _result = null; _recs = null; }),
            )
          : _buildInputView(),
    );
  }

  Widget _buildInputView() {
    return Column(children: [
      // ── Interactive map ──────────────────────────────────────
      Expanded(
        flex: 5,
        child: Stack(children: [
          // Map
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _pinned,
              initialZoom: 13,
              onTap: (_, latLng) => setState(() => _pinned = latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carbontech.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _pinned,
                  width: 48, height: 48,
                  child: Column(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                          color: kPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.agriculture_rounded,
                          color: Colors.white, size: 18),
                    ),
                    CustomPaint(
                      size: const Size(12, 8),
                      painter: _TrianglePainter(),
                    ),
                  ]),
                ),
              ]),
            ],
          ),

          // Top label
          Positioned(
            top: 12, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: kShadowSm,
              ),
              child: Row(children: [
                const Icon(Icons.touch_app_rounded, color: kPrimary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Tap map to select farm location',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kTextDark)),
                ),
              ]),
            ),
          ),

          // Coordinates pill
          Positioned(
            bottom: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: kShadowSm,
              ),
              child: Text(
                '${_pinned.latitude.toStringAsFixed(4)}, ${_pinned.longitude.toStringAsFixed(4)}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextMid),
              ),
            ),
          ),

          // Live location button
          Positioned(
            bottom: 12, right: 12,
            child: FloatingActionButton.small(
              backgroundColor: kPrimary,
              onPressed: _locating ? null : _goToLiveLocation,
              tooltip: 'Use my location',
              child: _locating
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded,
                      color: Colors.white, size: 20),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.white.withValues(alpha: 0.85),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(
                    width: 48, height: 48,
                    child: CircularProgressIndicator(
                        color: kPrimary, strokeWidth: 3),
                  ),
                  const SizedBox(height: 14),
                  Text(_loadStep,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kPrimary)),
                ]),
              ),
            ),
        ]),
      ),

      // ── Controls panel ──────────────────────────────────────
      TopRoundedContainer(
        color: kBgWhite,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(children: [
            Row(children: [
              Expanded(child: _DateBtn('From', _from, () => _pickDate(isFrom: true))),
              const SizedBox(width: 12),
              Expanded(child: _DateBtn('To', _to, () => _pickDate(isFrom: false))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: _crop,
                decoration: const InputDecoration(labelText: 'Crop', isDense: true),
                items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _crop = v!),
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: _stage,
                decoration: const InputDecoration(labelText: 'Stage', isDense: true),
                items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _stage = v!),
              )),
            ]),
            const SizedBox(height: 16),
            SafeArea(
              child: AnimatedOpacity(
                opacity: _loading ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _fetchData,
                  icon: const Icon(Icons.satellite_alt_rounded, size: 18),
                  label: const Text('Fetch Satellite Data'),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ── Triangle painter for map pin ──────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kPrimary;
    final path  = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Date button ───────────────────────────────────────────────────────────────

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateBtn(this.label, this.date, this.onTap);

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_today_rounded, size: 14),
        label: Text('$label: ${DateFormat('dd MMM').format(date)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          foregroundColor: kPrimary,
          side: const BorderSide(color: kBorder),
          backgroundColor: kBgCard,
        ),
      );
}

// ── Result View ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final SatelliteResult result;
  final GeminiRecommendations? recs;
  final String crop, stage;
  final LatLng pinned;
  final VoidCallback onRescan;

  const _ResultView({
    required this.result, required this.recs,
    required this.crop, required this.stage,
    required this.pinned, required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    final color = result.healthScore > 70
        ? kPrimary
        : result.healthScore > 40
            ? kAmber
            : kRed;
    final label = result.healthScore > 70
        ? 'Healthy'
        : result.healthScore > 40
            ? 'Moderate'
            : 'Stressed';
    final ndviHistory = MockData.ndviHistory;

    return ListView(children: [
      // ── Mini map showing selected location ────────────────
      SizedBox(
        height: 160,
        child: FlutterMap(
          options: MapOptions(initialCenter: pinned, initialZoom: 14, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.carbontech.app'),
            MarkerLayer(markers: [
              Marker(
                point: pinned, width: 48, height: 48,
                child: Column(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                    child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 18),
                  ),
                  CustomPaint(size: const Size(12, 8), painter: _TrianglePainter()),
                ]),
              ),
            ]),
          ],
        ),
      ),

      // ── Score header ─────────────────────────────────────
      Container(
        color: color.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(children: [
          SizedBox(width: 110, height: 110,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: result.healthScore / 100, strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${result.healthScore.round()}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
                Text('/100', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          StatusBadge(label, color),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.satellite_alt_rounded, color: kTextGrey, size: 12),
            const SizedBox(width: 4),
            Text('Last pass: ${DateFormat('dd MMM yyyy').format(result.satelliteDate)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey)),
            if (result.source == 'cache') ...[const SizedBox(width: 6), StatusBadge('CACHED', kAccentGold)]
            else if (result.source == 'mock') ...[const SizedBox(width: 6), StatusBadge('DEMO', kAccentBlue)],
          ]),
        ]),
      ),

      // ── Metrics ───────────────────────────────────────────
      TopRoundedContainer(
        color: kBgWhite,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$crop  ·  $stage',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
            const SizedBox(height: 4),
            Text('${pinned.latitude.toStringAsFixed(4)}, ${pinned.longitude.toStringAsFixed(4)}  ·  Sentinel-2',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextGrey)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: kBorder)),
            Text('Satellite Metrics',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _MetricTile('NDVI',    result.ndvi.toStringAsFixed(3),    '',          kPrimary),
                _MetricTile('Biomass', result.biomass.toStringAsFixed(2), 'tons/ha',   kAccentBlue),
                _MetricTile('Carbon',  result.carbon.toStringAsFixed(2),  'tons C/ha', kGreenSoft),
                _MetricTile('CO₂e',   result.co2e.toStringAsFixed(2),    'tons/ha',   kAccentGold),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: kBorder)),
            _CarbonCreditBox(result: result),
          ]),
        ),
      ),

      // ── NDVI chart + recs ─────────────────────────────────
      TopRoundedContainer(
        color: kBgPage,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NDVI Trend (30 days)',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 16),
            SizedBox(height: 110, child: LineChart(LineChartData(
              minY: 0.2, maxY: 0.85,
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [LineChartBarData(
                spots: ndviHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true, curveSmoothness: 0.4, color: kPrimary, barWidth: 2.5,
                dotData: FlDotData(show: true,
                  getDotPainter: (s, p, d, i) => FlDotCirclePainter(
                    radius: i == ndviHistory.length - 1 ? 5 : 0,
                    color: kPrimary, strokeWidth: 2.5, strokeColor: kBgWhite)),
                belowBarData: BarAreaData(show: true,
                  gradient: LinearGradient(
                    colors: [kPrimary.withValues(alpha: 0.15), kPrimary.withValues(alpha: 0.0)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              )],
            ))),
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: kAccentGold, size: 16),
              const SizedBox(width: 6),
              Text('AI Recommendations',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
              const SizedBox(width: 6),
              StatusBadge('AI', kAccentGold),
            ]),
            const SizedBox(height: 14),
            if (recs != null)
              ...recs!.asList.asMap().entries.map((e) => _RecRow(e.key + 1, e.value))
            else
              const Center(child: CircularProgressIndicator(color: kPrimary)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: onRescan,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('New Analysis'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => context.go('/sell'),
                icon: const Icon(Icons.sell_rounded, size: 16),
                label: const Text('Sell Credits'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
              )),
            ]),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    ]);
  }
}

class _MetricTile extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _MetricTile(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          Container(width: 4, height: 30, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            if (unit.isNotEmpty)
              Text(unit, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTextGrey)),
          ]),
        ]),
      );
}

class _CarbonCreditBox extends StatelessWidget {
  final SatelliteResult result;
  const _CarbonCreditBox({required this.result});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPrimaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Carbon Credits', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
            StatusBadge('ELIGIBLE', kPrimary),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _CreditStat(result.carbonCredits.toStringAsFixed(2), 'tons CO₂e'),
            Container(width: 1, height: 36, color: kBorder),
            _CreditStat('₹${result.farmerPayment.toStringAsFixed(0)}', 'Your payout (90%)'),
          ]),
        ]),
      );
}

class _CreditStat extends StatelessWidget {
  final String value, label;
  const _CreditStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
      ]);
}

class _RecRow extends StatelessWidget {
  final int idx;
  final String text;
  const _RecRow(this.idx, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 24, height: 24,
            decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(7)),
            child: Center(child: Text(idx.toString(),
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: kPrimary)))),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextMid, height: 1.45))),
        ]),
      );
}
