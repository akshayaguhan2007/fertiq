import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/app_strings.dart';
import '../theme.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});
  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final _api = ApiService();
  SensorResult? _result;
  bool _loading = false;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    SensorResult? r = await _api.fetchLatestReading('demo-farm-1');
    r ??= await _api.simulateFallback();
    setState(() { _result = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(AppStrings.of(context).soilSensors),
        actions: [
          IconButton(
            icon: AnimatedRotation(
              turns: _loading ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: const Icon(Icons.refresh_rounded),
            ),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _result == null
              ? _EmptyState(onRetry: _fetch)
              : RefreshIndicator(
                  color: kGreen,
                  onRefresh: () async => _fetch(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _SourceBar(source: _result!.source),
                      const SizedBox(height: 16),
                      _HealthHeader(result: _result!),
                      const SizedBox(height: 16),
                      _SectionTitle('${AppStrings.of(context).nitrogen.replaceAll(' (N)', '')} (NPK)'),
                      const SizedBox(height: 10),
                      _NpkRow(result: _result!),
                      const SizedBox(height: 16),
                      _SectionTitle('4-in-1 Sensor'),                      const SizedBox(height: 10),
                      _EnvGrid(result: _result!),
                      const SizedBox(height: 16),
                      _CarbonBanner(result: _result!),
                      const SizedBox(height: 16),
                      _RecsCard(recs: _result!.recommendations),
                    ],
                  ),
                ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off_rounded, size: 56, color: kTextGrey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(AppStrings.of(context).noData, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: kTextGrey)),
            const SizedBox(height: 6),
            Text('Make sure the Raspberry Pi is online', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextLight)),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
          ],
        ),
      );
}

// ── Source bar ────────────────────────────────────────────────────────────────

class _SourceBar extends StatelessWidget {
  final String source;
  const _SourceBar({required this.source});
  @override
  Widget build(BuildContext context) {
    final live = source == 'hardware';
    final color = live ? kGreenSoft : kAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)]),
          ),
          const SizedBox(width: 10),
          Text(live ? 'Live — Raspberry Pi' : 'Demo data — connect Pi for live readings',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const Spacer(),
          Text(live ? 'LIVE' : 'DEMO',
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kTextGrey, letterSpacing: 0.5));
}

// ── Health header ─────────────────────────────────────────────────────────────

class _HealthHeader extends StatelessWidget {
  final SensorResult result;
  const _HealthHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.healthScore;
    final color = score > 70 ? kGreenSoft : score > 40 ? kAmber : kRed;
    final label = score > 70 ? 'Good' : score > 40 ? 'Moderate' : 'Poor';
    final bgColor = score > 70 ? kGreenTint : score > 40 ? kAmberTint : kRedTint;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: kShadowMd,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92, height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${score.round()}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                    Text('/ 100', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOIL HEALTH SCORE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: kTextGrey, letterSpacing: 1.1)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                ),
                const SizedBox(height: 10),
                _MiniStat('NDVI', result.ndviProxy.toStringAsFixed(3), kGreenSoft),
                _MiniStat('Temp', '${result.temperature.toStringAsFixed(1)}°C', kAmber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Text('$label  ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey)),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

// ── NPK row ───────────────────────────────────────────────────────────────────

class _NpkRow extends StatelessWidget {
  final SensorResult result;
  const _NpkRow({required this.result});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          _NpkTile('N', 'Nitrogen',   result.n, 80,  kGreen),
          const SizedBox(width: 10),
          _NpkTile('P', 'Phosphorus', result.p, 40,  kAmber),
          const SizedBox(width: 10),
          _NpkTile('K', 'Potassium',  result.k, 200, kRed),
        ],
      );
}

class _NpkTile extends StatelessWidget {
  final String symbol, name;
  final double value, optimal;
  final Color color;
  const _NpkTile(this.symbol, this.name, this.value, this.optimal, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = (value / optimal).clamp(0.0, 1.0);
    final status = value < optimal * 0.6 ? 'LOW' : value > optimal * 1.2 ? 'HIGH' : 'GOOD';
    final statusColor = status == 'GOOD' ? kGreenSoft : status == 'HIGH' ? kAmber : kRed;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: kShadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(symbol,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w800, color: color)),
                  ),
                ),
                StatusBadge(status, statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Text('${value.round()}',
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: kTextDark)),
            Text('ppm', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: kTextGrey)),
          ],
        ),
      ),
    );
  }
}

// ── Env grid ──────────────────────────────────────────────────────────────────

class _EnvGrid extends StatelessWidget {
  final SensorResult result;
  const _EnvGrid({required this.result});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              _EnvTile(Icons.water_drop_outlined,  'Moisture',    result.moisture.toStringAsFixed(1),    '%',     result.moisture,    0, 100, 20, 50, kBlue),
              const SizedBox(width: 10),
              _EnvTile(Icons.thermostat_outlined,  'Temperature', result.temperature.toStringAsFixed(1), '°C', result.temperature, 0,  60, 15, 35, kAmber),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _EnvTile(Icons.bolt_outlined,        'EC',          result.ec.toStringAsFixed(2), 'mS/cm', result.ec, 0, 4, 0.5, 2.0, kGreenSoft),
              const SizedBox(width: 10),
              _EnvTile(Icons.science_outlined,     'pH',          result.ph.toStringAsFixed(1), '',      result.ph, 3, 10, 6.0, 7.5, Color(0xFF8B5CF6)),
            ],
          ),
        ],
      );
}

class _EnvTile extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final double raw, min, max, optLow, optHigh;
  final Color color;
  const _EnvTile(this.icon, this.label, this.value, this.unit,
      this.raw, this.min, this.max, this.optLow, this.optHigh, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = ((raw - min) / (max - min)).clamp(0.0, 1.0);
    final ok  = raw >= optLow && raw <= optHigh;
    final statusColor = ok ? kGreenSoft : kAmber;
    final status = ok ? 'OPTIMAL' : raw < optLow ? 'LOW' : 'HIGH';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: kShadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                StatusBadge(status, statusColor),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: value,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22, fontWeight: FontWeight.w800, color: kTextDark)),
                  TextSpan(text: ' $unit',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextGrey)),
                ],
              ),
            ),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextGrey)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text('Optimal $optLow–$optHigh$unit',
                style: GoogleFonts.plusJakartaSans(fontSize: 9, color: kTextLight)),
          ],
        ),
      ),
    );
  }
}

// ── Carbon banner ─────────────────────────────────────────────────────────────

class _CarbonBanner extends StatelessWidget {
  final SensorResult result;
  const _CarbonBanner({required this.result});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3B20), Color(0xFF1B6B3A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CARBON ESTIMATE',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('${result.carbon.toStringAsFixed(3)} tons C/ha',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('${result.co2Equivalent.toStringAsFixed(3)} tons CO₂e/ha',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.white60)),
              ],
            ),
          ],
        ),
      );
}

// ── Recommendations ───────────────────────────────────────────────────────────

class _RecsCard extends StatelessWidget {
  final List<String> recs;
  const _RecsCard({required this.recs});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: kShadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.of(context).recommendations,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: kTextDark)),
            const SizedBox(height: 14),
            ...recs.asMap().entries.map((e) => _RecTile(index: e.key, text: e.value)),
          ],
        ),
      );
}

class _RecTile extends StatelessWidget {
  final int index;
  final String text;
  const _RecTile({required this.index, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: kGreenTint, borderRadius: BorderRadius.circular(7)),
              child: Center(
                child: Text('${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700, color: kGreen)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextMid, height: 1.45)),
            ),
          ],
        ),
      );
}
