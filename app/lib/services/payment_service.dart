import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';

class PaymentService {
  PaymentService._();
  static final instance = PaymentService._();

  // UPI VPA for CROP+ platform (replace with real VPA in production)
  static const _kPlatformVpa = 'cropplus@upi';
  static const _kPlatformName = 'CROP+ Carbon Platform';

  /// Builds a UPI deep-link and launches PhonePe / GPay / any UPI app.
  Future<bool> launchUpiPayment({
    required String creditId,
    required double amount,
    required String farmerName,
  }) async {
    final txnId = _generateTxnId();
    final note  = Uri.encodeComponent('Carbon Credit $creditId — CROP+');

    // Standard UPI intent URL (works with PhonePe, GPay, Paytm, BHIM)
    final upiUrl =
        'upi://pay?pa=$_kPlatformVpa&pn=${Uri.encodeComponent(_kPlatformName)}'
        '&am=${amount.toStringAsFixed(2)}&cu=INR'
        '&tn=$note&tr=$txnId';

    final uri = Uri.parse(upiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  /// Simulates payment verification (replace with Firestore webhook in prod).
  Future<PaymentModel> verifyPayment({
    required String creditId,
    required String farmerId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate network
    final success = Random().nextBool(); // 50/50 mock result
    return PaymentModel(
      id: _generateTxnId(),
      creditId: creditId,
      farmerId: farmerId,
      amount: amount,
      upiTransactionId: 'TXN${_generateTxnId()}',
      status: success ? PaymentStatus.completed : PaymentStatus.failed,
      method: PaymentMethod.upi,
      createdAt: DateTime.now(),
    );
  }

  /// Builds a UPI QR string for display via qr_flutter.
  String buildUpiQrData({required String creditId, required double amount}) {
    final note = Uri.encodeComponent('Carbon Credit $creditId');
    return 'upi://pay?pa=$_kPlatformVpa'
        '&pn=${Uri.encodeComponent(_kPlatformName)}'
        '&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$note';
  }

  String _generateTxnId() =>
      'CROP${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9999)}';
}
