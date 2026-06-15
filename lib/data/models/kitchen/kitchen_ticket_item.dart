class KitchenTicketItem {
  KitchenTicketItem({
    required this.id,
    required this.productName,
    required this.quantity,
    this.notes,
  });

  final int id;
  final String productName;
  final int quantity;
  final String? notes;

  factory KitchenTicketItem.fromJson(Map<String, dynamic> json) => KitchenTicketItem(
        id: json['id'] as int,
        productName: json['productName'] as String,
        quantity: json['quantity'] as int,
        notes: json['notes'] as String?,
      );
}
