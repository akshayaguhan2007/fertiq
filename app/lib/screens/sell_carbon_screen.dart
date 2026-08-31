import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_strings.dart';
import '../services/carbon_market_service.dart';
import '../services/satellite_service.dart';
import '../services/sensor_service.dart';
import '../theme.dart';

IconData _offerIcon(String emojiIcon) {
  if (emojiIcon == '🏛️') return Icons.account_balance_outlined;
  if (emojiIcon == '🌐') return Icons.language_outlined;
  return Icons.eco_outlined;
}

// Market offers use live price as base; premiums are multipliers
// Gov = 1.0×, International = 1.36×, Premium = 1.71×
class _MarketOffer {
  final String name, icon, paymentDays, tag;
  final double priceMultiplier; // applied to live market price
  const _MarketOffer({
    required this.name, required this.icon, required this.priceMultiplier,
    required this.paymentDays, required this.tag,
  });

  double priceInr(double marketPriceInr) => marketPriceInr * priceMultiplier;
}

const _kOffers = [
  _MarketOffer(name: 'Government Market (CCTS)', icon: '🏛️', priceMultiplier: 1.0,  paymentDays: '3–5 days',  tag: ''),
  _MarketOffer(name: 'International Buyer (Microsoft)', icon: '🌐', priceMultiplier: 1.36, paymentDays: '7–10 days', tag: 'BEST PRICE'),
  _MarketOffer(name: 'Premium Buyer (Agroforestry)', icon: '🌱', priceMultiplier: 1.71, paymentDays: '5–7 days',  tag: 'HIGHEST PRICE'),
];

class SellCarbonScreen extends StatefulWidget {
  const SellCarbonScreen({super.key});
  @override
  State<SellCarbonScreen> createState() => _SellCarbonScreenState();
}

class _SellCarbonScreenState extends State<SellCarbonScreen> {
  double _eligibleCredits = 0;
  CarbonMarketPrice? _market;
  bool _loading = true;
  bool _sold = false;
  _MarketOffer? _chosenOffer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      SatelliteService().loadCache(),
      CarbonMarketService.instance.fetchPrice(),
      SensorService().fetchOnce(),
    ]);
    final sat    = results[0] as SatelliteResult?;
    final market = results[1] as CarbonMarketPrice;
    final live   = results[2] as LiveSensorData;
    double credits = 0;
    if (sat != null && sat.carbonCredits > 0) {
      credits = sat.carbonCredits;
    } else {
      credits = live.co2Equivalent;
    }
    if (mounted) {
      setState(() {
        _eligibleCredits = credits;
        _market = market;
        _loading = false;
      });
    }
  }

  void _sell(_MarketOffer offer) async {
    final confirmed = await _showConfirm(offer);
    if (!confirmed) { return; }
    setState(() { _sold = true; _chosenOffer = offer; });
  }

  Future<bool> _showConfirm(_MarketOffer offer) async {
    final price = offer.priceInr(_market?.priceInr ?? 800);
    final payout = (_eligibleCredits * price * 0.90).toStringAsFixed(0);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Confirm Sale — ${offer.name}'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_eligibleCredits.toStringAsFixed(3)} tons CO₂e'),
              const SizedBox(height: 8),
              const Text('You will receive (90% share):', style: TextStyle(color: kTextGrey, fontSize: 13)),
              Text('₹$payout',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kGreen)),
              const SizedBox(height: 4),
              Text('Rate: ₹${price.toStringAsFixed(0)} / credit  ·  Payment: ${offer.paymentDays}',
                  style: const TextStyle(fontSize: 12, color: kTextGrey)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sell Now')),
            ],
          ),
        ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_sold && _chosenOffer != null) {
      return _PaymentSuccessScreen(
        offer: _chosenOffer!,
        credits: _eligibleCredits,
        marketPriceInr: _market?.priceInr ?? 800,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).sellCarbonTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kGreen.withValues(alpha: 0.9), kGreenLight.withValues(alpha: 0.9)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(AppStrings.of(context).sellCredits,
                            style: const TextStyle(color: Colors.white70, fontSize: 11,
                                fontWeight: FontWeight.w600, letterSpacing: 1)),
                        Text('${_eligibleCredits.toStringAsFixed(3)} tons CO₂e',
                            style: const TextStyle(color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text(AppStrings.of(context).eligible,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: kTextGrey, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  ..._kOffers.map((o) => _OfferCard(
                      offer: o,
                      credits: _eligibleCredits,
                      marketPriceInr: _market?.priceInr ?? 800,
                      onSell: () => _sell(o))),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _sell(_kOffers.last),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(AppStrings.of(context).sell),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreenSoft,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _MarketOffer offer;
  final double credits;
  final double marketPriceInr;
  final VoidCallback onSell;
  const _OfferCard({required this.offer, required this.credits,
      required this.marketPriceInr, required this.onSell});

  @override
  Widget build(BuildContext context) {
    final price  = offer.priceInr(marketPriceInr);
    final payout = credits * price * 0.90;
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_offerIcon(offer.icon), color: tagColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(offer.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark))),
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
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('₹${price.toStringAsFixed(0)} per credit',
                  style: const TextStyle(fontSize: 13, color: kTextGrey)),
              Text('You earn: ₹${payout.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kGreen)),
              Text('Payment: ${offer.paymentDays}',
                  style: const TextStyle(fontSize: 12, color: kTextGrey)),
            ])),
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
          ]),
        ]),
      ),
    );
  }
}

class _PaymentSuccessScreen extends StatelessWidget {
  final _MarketOffer offer;
  final double credits;
  final double marketPriceInr;
  const _PaymentSuccessScreen({
    required this.offer, required this.credits, required this.marketPriceInr});

  @override
  Widget build(BuildContext context) {
    final price  = offer.priceInr(marketPriceInr);
    final payout = (credits * price * 0.90).toStringAsFixed(0);
    final txnId  = 'CARBON-TN-${DateTime.now().year}-00${(123 + DateTime.now().second)}';
    final date   = DateFormat('MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).payment)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
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
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(AppStrings.of(context).certificate,
                  style: const TextStyle(color: Colors.white70, fontSize: 13,
                      fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('₹$payout',
                  style: const TextStyle(color: Colors.white, fontSize: 42,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Credited to your account',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Transaction Details',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextDark)),
                const Divider(height: 20),
                _TxRow('Credits Sold', '${credits.toStringAsFixed(3)} tons CO₂e'),
                _TxRow('Buyer', offer.name),
                _TxRow('Price', '₹${price.toStringAsFixed(0)} per credit (90% share)'),
                _TxRow('You Receive', '₹$payout'),
                _TxRow('Date', date),
                _TxRow('Transaction ID', '#$txnId'),
                _TxRow('Paid via', 'UPI (******@okhdfcbank)'),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: Text(AppStrings.of(context).certificate),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined, size: 16),
              label: Text(AppStrings.of(context).share),
            )),
          ]),
          const SizedBox(height: 80),
        ]),
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
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kTextGrey)),
          Flexible(child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark),
              textAlign: TextAlign.end)),
        ]),
      );
}
