enum PaymentMethod { upi, bank }
enum PaymentStatus { pending, processing, completed, failed }

class PaymentModel {
  final String id;
  final String creditId;
  final String farmerId;
  final double amount;
  final String upiTransactionId;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime createdAt;
  final String? receiptUrl;

  const PaymentModel({
    required this.id,
    required this.creditId,
    required this.farmerId,
    required this.amount,
    required this.upiTransactionId,
    required this.status,
    required this.method,
    required this.createdAt,
    this.receiptUrl,
  });

  PaymentModel copyWith({PaymentStatus? status, String? upiTransactionId, String? receiptUrl}) =>
      PaymentModel(
        id: id, creditId: creditId, farmerId: farmerId,
        amount: amount, method: method, createdAt: createdAt,
        upiTransactionId: upiTransactionId ?? this.upiTransactionId,
        status: status ?? this.status,
        receiptUrl: receiptUrl ?? this.receiptUrl,
      );

  Map<String, dynamic> toMap() => {
    'id': id, 'creditId': creditId, 'farmerId': farmerId,
    'amount': amount,
    'upiTransactionId': upiTransactionId,
    'status': status.name,
    'method': method.name,
    'createdAt': createdAt.toIso8601String(),
    'receiptUrl': receiptUrl,
  };
}
