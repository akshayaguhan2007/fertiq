import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../theme.dart';

class PaymentScreen extends StatefulWidget {
  final String creditId;
  final double amount;
  final double creditsCount;
  const PaymentScreen({
    super.key,
    required this.creditId,
    required this.amount,
    required this.creditsCount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentStatus _status = PaymentStatus.pending;
  PaymentModel? _result;
  bool _verifying = false;

  String get _qrData => PaymentService.instance.buildUpiQrData(
      creditId: widget.creditId, amount: widget.amount);

  Future<void> _launchUpi() async {
    setState(() => _status = PaymentStatus.processing);
    final launched = await PaymentService.instance.launchUpiPayment(
      creditId: widget.creditId,
      amount: widget.amount,
      farmerName: 'Ramesh Kumar',
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No UPI app found. Scan QR code instead.')),
      );
      setState(() => _status = PaymentStatus.pending);
    }
  }

  Future<void> _verifyPayment() async {
    setState(() => _verifying = true);
    final result = await PaymentService.instance.verifyPayment(
      creditId: widget.creditId,
      farmerId: 'demo-uid',
      amount: widget.amount,
    );
    if (mounted) setState(() { _result = result; _status = result.status; _verifying = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        title: const Text('Pay via UPI'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _AmountCard(amount: widget.amount, credits: widget.creditsCount),
          const SizedBox(height: 20),
          if (_status == PaymentStatus.completed)
            _SuccessView(payment: _result!)
          else if (_status == PaymentStatus.failed)
            _FailedView(onRetry: () => setState(() => _status = PaymentStatus.pending))
          else ...[
            _QrCard(qrData: _qrData, amount: widget.amount),
            const SizedBox(height: 16),
            _StatusBanner(status: _status),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _status == PaymentStatus.processing ? null : _launchUpi,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(_status == PaymentStatus.processing ? 'Opening UPI app…' : 'Pay with UPI App'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _verifying ? null : _verifyPayment,
              icon: _verifying
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_verifying ? 'Verifying…' : 'I have paid — Verify'),
            ),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final double amount, credits;
  const _AmountCard({required this.amount, required this.credits});

  @override
  Widget build(BuildContext context) => GlassCard(
        glow: true,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Amount to Receive', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextGrey)),
              const SizedBox(height: 4),
              Text('₹${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w900, color: kPrimary)),
              Text('${credits.toStringAsFixed(3)} tons CO₂e',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              const Icon(Icons.eco_rounded, color: kPrimary, size: 20),
              const SizedBox(height: 2),
              Text('Carbon\nCredit', textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary)),
            ]),
          ),
        ]),
      );
}

class _QrCard extends StatelessWidget {
  final String qrData;
  final double amount;
  const _QrCard({required this.qrData, required this.amount});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(children: [
          Text('Scan to Pay', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
          const SizedBox(height: 4),
          Text('Use PhonePe, GPay, Paytm or any UPI app',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextGrey)),
          const SizedBox(height: 16),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 180,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.account_circle_outlined, color: kTextGrey, size: 16),
            const SizedBox(width: 6),
            Text('cropplus@upi', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextMid)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'cropplus@upi'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('UPI ID copied!')),
                );
              },
              child: const Icon(Icons.copy_rounded, size: 16, color: kPrimary),
            ),
          ]),
        ]),
      );
}

class _StatusBanner extends StatelessWidget {
  final PaymentStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == PaymentStatus.pending) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kAccentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccentGold.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kAccentGold)),
        const SizedBox(width: 10),
        Text('Payment in progress…',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kAccentGold)),
      ]),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final PaymentModel payment;
  const _SuccessView({required this.payment});

  @override
  Widget build(BuildContext context) => GlassCard(
        glow: true,
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: kPrimary, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Payment Successful!',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: kPrimary)),
          const SizedBox(height: 8),
          Text('₹${payment.amount.toStringAsFixed(0)} credited to your account',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: kTextMid)),
          const SizedBox(height: 16),
          _TxnRow('Transaction ID', payment.upiTransactionId),
          _TxnRow('Date', payment.createdAt.toString().substring(0, 16)),
          _TxnRow('Method', 'UPI'),
          _TxnRow('Status', 'Completed'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payment.upiTransactionId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction ID copied')),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text('Copy Receipt'),
          ),
        ]),
      );
}

class _TxnRow extends StatelessWidget {
  final String label, value;
  const _TxnRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
        ]),
      );
}

class _FailedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _FailedView({required this.onRetry});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: kAccentRed.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.cancel_rounded, color: kAccentRed, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Payment Failed',
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: kAccentRed)),
          const SizedBox(height: 8),
          Text('Please try again or contact support',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: kTextMid)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
          ),
        ]),
      );
}
