import 'order_item.dart';
import 'order_selection.dart';

class Order {
  static const int openStatus = 1;
  static const int billRequestedStatus = 2;
  static const int paidStatus = 3;
  static const int cancelledStatus = 4;

  Order({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.items,
    required this.selections,
  });

  final int id;
  final int tableId;
  final String tableName;
  final int status;
  final DateTime createdAt;
  final double total;
  final List<OrderItem> items;
  final List<OrderSelection> selections;

  bool get isOpen => status == openStatus;
  bool get isWaitingPayment => status == billRequestedStatus;
  bool get isPaid => status == paidStatus;
  bool get isCancelled => status == cancelledStatus;
  bool get isEmpty => total <= 0 || (items.isEmpty && selections.isEmpty);

  bool get isPayable => !isEmpty;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int,
    tableId: json['tableId'] as int,
    tableName: json['tableName'] as String,
    status: json['status'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    total: (json['total'] as num).toDouble(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    selections: (json['selections'] as List<dynamic>? ?? const [])
        .map(
          (selection) =>
              OrderSelection.fromJson(selection as Map<String, dynamic>),
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableId': tableId,
    'tableName': tableName,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'total': total,
    'items': items.map((item) => item.toJson()).toList(),
    'selections': selections.map((selection) => selection.toJson()).toList(),
  };
}
