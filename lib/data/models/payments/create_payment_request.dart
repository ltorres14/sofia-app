class CreatePaymentRequest {
  CreatePaymentRequest({
    required this.orderId,
    required this.amount,
    required this.method,
    required this.userId,
  });

  final int orderId;
  final double amount;
  final int method;
  final int userId;

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'amount': amount,
        'method': method,
        'userId': userId,
      };
}
