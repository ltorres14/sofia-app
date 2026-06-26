class CreatePaymentRequest {
  CreatePaymentRequest({
    required this.orderId,
    required this.amount,
    required this.method,
    required this.userId,
    this.comments,
  });

  final int orderId;
  final double amount;
  final int method;
  final int userId;
  final String? comments;

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'amount': amount,
    'method': method,
    'comments': comments?.trim() ?? '',
    'userId': userId,
  };
}
