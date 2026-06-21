import 'order_selection_item.dart';

class OrderSelection {
  OrderSelection({
    required this.id,
    required this.sequenceNumber,
    required this.label,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.items,
  });

  final int id;
  final int sequenceNumber;
  final String label;
  final String? notes;
  final int status;
  final DateTime createdAt;
  final double total;
  final List<OrderSelectionItem> items;

  factory OrderSelection.fromJson(Map<String, dynamic> json) => OrderSelection(
    id: json['id'] as int,
    sequenceNumber: json['sequenceNumber'] as int? ?? 0,
    label: json['label'] as String? ?? '',
    notes: json['notes'] as String?,
    status: json['status'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    total: (json['total'] as num).toDouble(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => OrderSelectionItem.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sequenceNumber': sequenceNumber,
    'label': label,
    'notes': notes,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'total': total,
    'items': items.map((item) => item.toJson()).toList(),
  };
}
