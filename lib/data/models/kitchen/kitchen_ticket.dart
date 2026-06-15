import 'kitchen_ticket_item.dart';

class KitchenTicket {
  KitchenTicket({
    required this.id,
    required this.orderId,
    required this.tableName,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final int orderId;
  final String tableName;
  final int status;
  final DateTime createdAt;
  final List<KitchenTicketItem> items;

  factory KitchenTicket.fromJson(Map<String, dynamic> json) => KitchenTicket(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        tableName: json['tableName'] as String,
        status: json['status'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        items: (json['items'] as List<dynamic>)
            .map((item) => KitchenTicketItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
