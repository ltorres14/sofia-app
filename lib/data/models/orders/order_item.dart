class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    required this.sentToKitchen,
  });

  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? notes;
  final bool sentToKitchen;

  double get total => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int,
        productId: json['productId'] as int,
        productName: json['productName'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        notes: json['notes'] as String?,
        sentToKitchen: json['sentToKitchen'] as bool? ?? false,
      );
}
