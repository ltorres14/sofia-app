import 'kitchen_ticket_item.dart';
import 'kitchen_ticket_selection.dart';

class KitchenTicket {
  KitchenTicket({
    required this.id,
    required this.orderId,
    required this.tableName,
    required this.status,
    required this.createdAt,
    required this.selections,
    required this.legacyItems,
  });

  final int id;
  final int orderId;
  final String tableName;
  final int status;
  final DateTime createdAt;
  final List<KitchenTicketSelection> selections;
  final List<KitchenTicketItem> legacyItems;

  List<KitchenTicketItem> get items => [
    for (final selection in selections) ...selection.items,
    ...legacyItems,
  ];

  factory KitchenTicket.fromJson(Map<String, dynamic> json) {
    final selections = (json['selections'] as List<dynamic>? ?? const [])
        .map(
          (selection) => KitchenTicketSelection.fromJson(
            selection as Map<String, dynamic>,
          ),
        )
        .toList();
    final legacyItemsRaw =
        (json['legacyItems'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        const [];

    return KitchenTicket(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        tableName: json['tableName'] as String,
        status: json['status'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        selections: selections,
        legacyItems: legacyItemsRaw
            .map((item) => KitchenTicketItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
  }
}
