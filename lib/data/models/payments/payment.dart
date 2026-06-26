class Payment {
  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.receivedByUserId,
    this.comments,
  });

  final int id;
  final int orderId;
  final double amount;
  final int method;
  final DateTime paidAt;
  final int receivedByUserId;
  final String? comments;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as int,
    orderId: json['orderId'] as int,
    amount: (json['amount'] as num).toDouble(),
    method: json['method'] as int,
    paidAt: DateTime.parse(json['paidAt'] as String),
    receivedByUserId: (json['receivedByUserId'] ?? json['userId']) as int,
    comments: json['comments'] as String?,
  );
}
