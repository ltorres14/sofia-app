import 'order_item.dart';

class Order {
  Order({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.items,
  });

  final int id;
  final int tableId;
  final String tableName;
  final int status;
  final DateTime createdAt;
  final double total;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        tableId: json['tableId'] as int,
        tableName: json['tableName'] as String,
        status: json['status'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        total: (json['total'] as num).toDouble(),
        items: (json['items'] as List<dynamic>)
            .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
