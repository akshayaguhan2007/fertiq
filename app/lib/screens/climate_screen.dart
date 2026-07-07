import 'package:flutter/material.dart';
import '../services/app_strings.dart';
import '../services/mock_data.dart';
import '../theme.dart';

class ClimateScreen extends StatelessWidget {
  const ClimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Overall risk = 0.4×drought + 0.2×flood + 0.4×heat
    const drought = 20.0, flood = 4.0, heat = 52.0;
    final overall = (0.4 * drought + 0.2 * flood + 0.4 * heat);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).climateRiskTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: kGreen, size: 16),
                  const SizedBox(width: 6),
                  const Text('Tanjavur, Tamil Nadu',
                      style: TextStyle(fontSize: 13, color: kGreen, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Text('15-Day Forecast',
                      style: TextStyle(fontSize: 12, color: kTextGrey)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Overall risk badge
            _OverallRiskCard(risk: overall),
            const SizedBox(height: 16),

            // Individual risks
            _RiskCard(drought: drought, flood: flood, heat: heat),
            const SizedBox(height: 16),

            // Detailed outlook table
            _ForecastTable(),
            const SizedBox(height: 16),

            // Heat stress alert
            _AlertBox(),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to calendar'))),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(AppStrings.of(context).addToCalendar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shared!'))),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('SHARE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _OverallRiskCard extends StatelessWidget {
  final double risk;
  const _OverallRiskCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    final color = risk > 60 ? kRed : risk > 35 ? kAmber : kGreenSoft;
    final label = risk > 60 ? 'HIGH' : risk > 35 ? 'MODERATE' : 'LOW';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.of(context).overallRisk,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700, letterSpacing: 1)),
              Text('${risk.round()}% ($label)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final double drought, flood, heat;
  const _RiskCard({required this.drought, required this.flood, required this.heat});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('15-DAY RISK ASSESSMENT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: kTextGrey, letterSpacing: 1.2)),
              const SizedBox(height: 14),
              _RiskBar(AppStrings.of(context).droughtRisk, drought, Icons.wb_sunny_outlined),
              _RiskBar(AppStrings.of(context).floodRisk,   flood,   Icons.waves_outlined),
              _RiskBar(AppStrings.of(context).heatStress,  heat,    Icons.thermostat_outlined),
            ],
          ),
        ),
      );
}

class _RiskBar extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  const _RiskBar(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final color = value > 60 ? kRed : value > 35 ? kAmber : kGreenSoft;
    final sev   = value > 60 ? 'HIGH' : value > 35 ? 'MEDIUM' : 'LOW';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 13, color: kTextDark)),
                ],
              ),
              Row(
                children: [
                  Text('${value.round()}%  ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sev, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value / 100, minHeight: 10,
              backgroundColor: const Color(0xFFE0E0E0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastTable extends StatelessWidget {
  const _ForecastTable();

  @override
  Widget build(BuildContext context) {
    final days = MockData.forecast.take(7).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DETAILED OUTLOOK',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: kTextGrey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _TableRow(
              AppStrings.of(context).day, AppStrings.of(context).temp,
              AppStrings.of(context).rain, AppStrings.of(context).moist,
              AppStrings.of(context).risk, isHeader: true),
            const Divider(height: 8),
            ...days.asMap().entries.map((e) {
              final d     = e.value;
              final color = d.risk == 'High' ? kRed : d.risk == 'Med' ? kAmber : kGreenSoft;
              return _TableRow(
                '${AppStrings.of(context).day} ${e.key + 1}',
                '${d.temp}°C',
                '${d.rain}mm',
                '${d.moisture}%',
                d.risk,
                riskColor: color,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String day, temp, rain, moist, risk;
  final bool isHeader;
  final Color? riskColor;
  const _TableRow(this.day, this.temp, this.rain, this.moist, this.risk,
      {this.isHeader = false, this.riskColor});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isHeader ? 10 : 12,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
      color: isHeader ? kTextGrey : kTextDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(day, style: style)),
          Expanded(child: Text(temp, style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(rain, style: style, textAlign: TextAlign.center)),
          Expanded(child: Text(moist, style: style, textAlign: TextAlign.center)),
          Expanded(
            child: Text(risk,
                style: style.copyWith(
                  color: isHeader ? kTextGrey : riskColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _AlertBox extends StatelessWidget {
  const _AlertBox();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kAmber.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(AppStrings.of(context).heatAlert,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kAmber)),
            const SizedBox(height: 8),
            ...[AppStrings.of(context).heatAlertTip1, AppStrings.of(context).heatAlertTip2, AppStrings.of(context).heatAlertTip3]
                .map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(tip, style: const TextStyle(fontSize: 13, color: kTextDark)),
                )),
          ],
        ),
      );
}
