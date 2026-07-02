import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class GaugeBar extends StatelessWidget {
  final String label;
  final double value;   // 0.0 – 1.0
  final String displayValue;
  final String unit;
  final Color color;
  final String? optimalRange;

  const GaugeBar({
    super.key,
    required this.label,
    required this.value,
    required this.displayValue,
    required this.unit,
    required this.color,
    this.optimalRange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: displayValue,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    TextSpan(
                        text: ' $unit',
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: value.clamp(0.0, 1.0),
            progressColor: color,
            backgroundColor: color.withValues(alpha: 0.12),
            barRadius: const Radius.circular(6),
            padding: EdgeInsets.zero,
          ),
          if (optimalRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('Optimal: $optimalRange',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9E9E9E))),
            ),
        ],
      ),
    );
  }
}
