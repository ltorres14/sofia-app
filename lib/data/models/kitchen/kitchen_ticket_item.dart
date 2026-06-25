class KitchenTicketItem {
  KitchenTicketItem({
    required this.id,
    required this.productName,
    required this.quantity,
    this.notes,
    this.role = 0,
    this.sortOrder = 0,
  });

  final int id;
  final String productName;
  final int quantity;
  final String? notes;
  final int role;
  final int sortOrder;

  factory KitchenTicketItem.fromJson(Map<String, dynamic> json) =>
      KitchenTicketItem(
        id: (json['id'] as int?) ?? 0,
        productName: json['productName'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String?,
        role: (json['role'] as int?) ?? 0,
        sortOrder: (json['sortOrder'] as int?) ?? 0,
      );
}
