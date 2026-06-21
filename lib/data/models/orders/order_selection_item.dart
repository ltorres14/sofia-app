class OrderSelectionItem {
  OrderSelectionItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.role,
    required this.sortOrder,
    this.notes,
  });

  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;
  final int role;
  final int sortOrder;
  final String? notes;

  factory OrderSelectionItem.fromJson(Map<String, dynamic> json) =>
      OrderSelectionItem(
        id: json['id'] as int,
        productId: json['productId'] as int,
        productName: json['productName'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        role: json['role'] as int,
        sortOrder: json['sortOrder'] as int? ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'total': total,
    'role': role,
    'sortOrder': sortOrder,
    'notes': notes,
  };
}
