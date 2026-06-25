import 'kitchen_ticket_item.dart';

class KitchenTicketSelection {
  KitchenTicketSelection({
    required this.orderSelectionId,
    required this.sequenceNumber,
    required this.label,
    this.comment,
    required this.items,
  });

  final int orderSelectionId;
  final int sequenceNumber;
  final String label;
  final String? comment;
  final List<KitchenTicketItem> items;

  factory KitchenTicketSelection.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((item) => KitchenTicketItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return KitchenTicketSelection(
      orderSelectionId: (json['orderSelectionId'] as int?) ?? 0,
      sequenceNumber: (json['sequenceNumber'] as int?) ?? 0,
      label: json['label'] as String? ?? '',
      comment: json['comment'] as String?,
      items: items,
    );
  }
}
