import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_strings.dart';
import '../services/mock_data.dart';
import '../theme.dart';

IconData _offerIcon(String emojiIcon) {
  if (emojiIcon == '🏛️') return Icons.account_balance_outlined;
  if (emojiIcon == '🌐') return Icons.language_outlined;
  return Icons.eco_outlined;
}

class SellCarbonScreen extends StatefulWidget {
  const SellCarbonScreen({super.key});

  @override
  State<SellCarbonScreen> createState() => _SellCarbonScreenState();
}

class _SellCarbonScreenState extends State<SellCarbonScreen> {
  bool _sold = false;
  MarketOffer? _chosenOffer;

  void _sell(MarketOffer offer) async {
    final confirmed = await _showConfirm(offer);
    if (!confirmed) return;
    setState(() { _sold = true; _chosenOffer = offer; });
  }

  Future<bool> _showConfirm(MarketOffer offer) async {
    const credits = MockData.co2eAdditional;
    final total   = (credits * offer.pricePerCredit).toStringAsFixed(0);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Confirm Sale — ${offer.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${credits.toStringAsFixed(1)} tons CO₂e'),
                const SizedBox(height: 8),
                const Text('You will receive:', style: TextStyle(color: kTextGrey, fontSize: 13)),
                Text('₹$total',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kGreen)),
                const SizedBox(height: 4),
                Text('Rate: ₹${offer.pricePerCredit.round()} / credit  ·  Payment: ${offer.paymentDays}',
                    style: const TextStyle(fontSize: 12, color: kTextGrey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sell Now')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_sold && _chosenOffer != null) return _PaymentSuccessScreen(offer: _chosenOffer!);

    const eligibleCredits = MockData.co2eAdditional;
    final offers = MockData.marketOffers;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).sellCarbonTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kGreen.withValues(alpha: 0.9), kGreenLight.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.of(context).sellCredits,
                          style: const TextStyle(color: Colors.white70, fontSize: 11,
                              fontWeight: FontWeight.w600, letterSpacing: 1)),
                      Text('${eligibleCredits.toStringAsFixed(1)} tons CO₂e',
                          style: const TextStyle(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.of(context).eligible,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: kTextGrey, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            ...offers.map((o) => _OfferCard(offer: o, credits: eligibleCredits, onSell: () => _sell(o))),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _sell(offers.last),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(AppStrings.of(context).sell),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreenSoft,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final MarketOffer offer;
  final double credits;
  final VoidCallback onSell;
  const _OfferCard({required this.offer, required this.credits, required this.onSell});

  @override
  Widget build(BuildContext context) {
    final total     = credits * offer.pricePerCredit;
    final isBest    = offer.tag == 'BEST PRICE';
    final isHighest = offer.tag == 'HIGHEST PRICE';
    final tagColor  = isHighest ? kAmber : isBest ? kGreenSoft : kGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (isBest || isHighest) ? tagColor.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_offerIcon(offer.icon), color: tagColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(offer.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark)),
                ),
                if (offer.tag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(offer.tag,
                        style: TextStyle(fontSize: 10, color: tagColor, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${offer.pricePerCredit.round()} per credit',
                          style: const TextStyle(fontSize: 13, color: kTextGrey)),
                      Text('Total: ₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kGreen)),
                      Text('Payment: ${offer.paymentDays}',
                          style: const TextStyle(fontSize: 12, color: kTextGrey)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onSell,
                  icon: const Icon(Icons.sell_outlined, size: 16),
                  label: const Text('Sell'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isBest || isHighest) ? tagColor : kGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Success Screen ────────────────────────────────────────────────────

class _PaymentSuccessScreen extends StatelessWidget {
  final MarketOffer offer;
  const _PaymentSuccessScreen({required this.offer});

  @override
  Widget build(BuildContext context) {
    const credits = MockData.co2eAdditional;
    final total   = (credits * offer.pricePerCredit).toStringAsFixed(0);
    final txnId   = 'CARBON-TN-${DateTime.now().year}-00${(123 + DateTime.now().second)}';
    final date    = DateFormat('MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).payment)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kGreen.withValues(alpha: 0.9), kGreenLight],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  Text(AppStrings.of(context).certificate,
                      style: const TextStyle(color: Colors.white70, fontSize: 13,
                          fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text('₹$total',
                      style: const TextStyle(color: Colors.white, fontSize: 42,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Credited to your account',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaction Details',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark)),
                    const Divider(height: 20),
                    _TxRow('Credits Sold', '${credits.toStringAsFixed(1)} tons CO₂e'),
                    _TxRow('Buyer', offer.name),
                    _TxRow('Price', '₹${offer.pricePerCredit.round()} per credit'),
                    _TxRow('Date', date),
                    _TxRow('Transaction ID', '#$txnId'),
                    _TxRow('Paid via', 'UPI (******@okhdfcbank)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: Text(AppStrings.of(context).certificate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: Text(AppStrings.of(context).share),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kAmber.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: kAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.track_changes_rounded, color: kAmber, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Next Target: Your soil can earn ₹45,000 next year. Plant 25 more trees to reach it!',
                      style: TextStyle(fontSize: 13, color: kTextDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final String label, value;
  const _TxRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: kTextGrey)),
            Flexible(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark),
                  textAlign: TextAlign.end),
            ),
          ],
        ),
      );
}
