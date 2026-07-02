import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mock_data.dart';
import '../theme.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final _yieldCtrl = TextEditingController(text: '5.0');
  bool _calculated = false;

  // Fertilizer calculation (matches backend logic)
  late _FertResult _result;

  void _calculate() {
    final targetYield = double.tryParse(_yieldCtrl.text) ?? 5.0;
    final soil = MockData.soilReading;

    // N-P-K removal rates for Rice (kg per ton yield)
    const nRemoval = 16.0, pRemoval = 8.0, kRemoval = 14.0;

    final nDemand = targetYield * nRemoval;
    final pDemand = targetYield * pRemoval;
    final kDemand = targetYield * kRemoval;

    final nSupply = soil.n * 2;
    final pSupply = soil.p * 2;
    final kSupply = soil.k * 2;

    final nDef = (nDemand - nSupply).clamp(0.0, 999.0);
    final pDef = (pDemand - pSupply).clamp(0.0, 999.0);
    final kDef = (kDemand - kSupply).clamp(0.0, 999.0);

    final urea = (nDef / 0.46);
    final dap  = (pDef / 0.20);
    final mop  = (kDef / 0.50);

    final cost = urea * 6 + dap * 27 + mop * 17;
    const traditional = 5000.0;

    setState(() {
      _result = _FertResult(
        nDemand: nDemand, pDemand: pDemand, kDemand: kDemand,
        nSupply: nSupply, pSupply: pSupply, kSupply: kSupply,
        nDef: nDef, pDef: pDef, kDef: kDef,
        urea: urea, dap: dap, mop: mop,
        cost: cost, savings: (traditional - cost).clamp(0, 9999),
      );
      _calculated = true;
    });
  }

  @override
  void dispose() {
    _yieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farm     = MockData.farm;
    final analysis = MockData.analysis;

    return Scaffold(
      appBar: AppBar(title: const Text('Fertilizer Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Crop: ${analysis.cropType}  |  Area: ${farm.area} ha  |  Soil: ${farm.soilType}',
                style: const TextStyle(fontSize: 13, color: kGreen, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // Soil Status
            _SoilStatusCard(soil: analysis.soil),
            const SizedBox(height: 16),

            // Target yield input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Yield',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _yieldCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                      decoration: const InputDecoration(
                        labelText: 'Expected yield (tons/ha)',
                        suffixText: 'tons/ha',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('CALCULATE FERTILIZER'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_calculated) ...[
              _RecommendationCard(result: _result),
              const SizedBox(height: 16),
              _ScheduleCard(result: _result),
              const SizedBox(height: 16),
              _ReminderRow(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SoilStatusCard extends StatelessWidget {
  final dynamic soil;
  const _SoilStatusCard({required this.soil});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SOIL STATUS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: kTextGrey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _SoilBar('Nitrogen', soil.n, 80, 'ppm', 'LOW'),
              _SoilBar('Phosphorus', soil.p, 30, 'ppm', 'OK'),
              _SoilBar('Potassium', soil.k, 150, 'ppm', 'HIGH'),
              _SoilBar('pH', soil.ph, 7.0, '', 'IDEAL'),
              _SoilBar('Moisture', soil.moisture, 50, '%', 'GOOD'),
            ],
          ),
        ),
      );
}

class _SoilBar extends StatelessWidget {
  final String label, unit, statusLabel;
  final double current, optimal;
  const _SoilBar(this.label, this.current, this.optimal, this.unit, this.statusLabel);

  @override
  Widget build(BuildContext context) {
    final pct   = (current / optimal).clamp(0.0, 1.0);
    final color = pct > 0.9 ? kGreenSoft : pct > 0.6 ? kGreenLight : kAmber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: kTextDark)),
              Row(
                children: [
                  Text('${current % 1 == 0 ? current.round() : current.toStringAsFixed(1)}$unit',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(statusLabel, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 7,
                backgroundColor: const Color(0xFFE0E0E0), color: color),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final _FertResult result;
  const _RecommendationCard({required this.result});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RECOMMENDED PRODUCTS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: kTextGrey, letterSpacing: 1.2)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _FertBox('Urea\n(46% N)', '${result.urea.round()} kg',
                      '₹${(result.urea * 6).round()}', kGreen),
                  const SizedBox(width: 8),
                  _FertBox('DAP\n(P source)', '${result.dap.round()} kg',
                      '₹${(result.dap * 27).round()}', kAmber),
                  const SizedBox(width: 8),
                  _FertBox('MOP\n(K source)', '${result.mop.round()} kg',
                      '₹${(result.mop * 17).round()}', kRed),
                ],
              ),
              const Divider(height: 24),
              _CostRow('TOTAL COST', '₹${result.cost.round()} per hectare', kTextDark),
              _CostRow('SAVINGS vs TRADITIONAL', '₹${result.savings.round()}!', kGreenSoft),
            ],
          ),
        ),
      );
}

class _FertBox extends StatelessWidget {
  final String label, qty, cost;
  final Color color;
  const _FertBox(this.label, this.qty, this.cost, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(label, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(qty, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kTextDark)),
              Text(cost, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      );
}

class _CostRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CostRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );
}

class _ScheduleCard extends StatelessWidget {
  final _FertResult result;
  const _ScheduleCard({required this.result});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('APPLICATION SCHEDULE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: kTextGrey, letterSpacing: 1.2)),
              const SizedBox(height: 14),
              _ScheduleItem('Today — Basal',
                  '${(result.urea * 0.5).round()} kg Urea + ${result.dap.round()} kg DAP'),
              _ScheduleItem('After 25 days — Tillering',
                  '${(result.urea * 0.25).round()} kg Urea'),
              _ScheduleItem('After 45 days — Panicle',
                  '${(result.urea * 0.25).round()} kg Urea'),
            ],
          ),
        ),
      );
}

class _ScheduleItem extends StatelessWidget {
  final String date, action;
  const _ScheduleItem(this.date, this.action);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10, height: 10, margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark)),
                  Text(action, style: const TextStyle(fontSize: 12, color: kTextGrey)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder set!'))),
              icon: const Icon(Icons.alarm, size: 18),
              label: const Text('SET REMINDER'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as done'), backgroundColor: kGreenSoft)),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('MARK DONE'),
            ),
          ),
        ],
      );
}

class _FertResult {
  final double nDemand, pDemand, kDemand;
  final double nSupply, pSupply, kSupply;
  final double nDef, pDef, kDef;
  final double urea, dap, mop;
  final double cost, savings;
  _FertResult({
    required this.nDemand, required this.pDemand, required this.kDemand,
    required this.nSupply, required this.pSupply, required this.kSupply,
    required this.nDef,    required this.pDef,    required this.kDef,
    required this.urea,    required this.dap,     required this.mop,
    required this.cost,    required this.savings,
  });
}
