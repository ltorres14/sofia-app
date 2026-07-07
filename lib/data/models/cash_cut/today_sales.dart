class TodaySalesResponse {
  TodaySalesResponse({required this.summary, required this.sales});

  final TodaySalesSummary summary;
  final List<TodaySale> sales;

  factory TodaySalesResponse.fromJson(Map<String, dynamic> json) =>
      TodaySalesResponse(
        summary: TodaySalesSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? const {},
        ),
        sales: (json['sales'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TodaySale.fromJson)
            .toList(growable: false),
      );
}

class TodaySalesSummary {
  TodaySalesSummary({
    required this.businessDate,
    required this.totalSold,
    required this.totalCash,
    required this.totalCard,
    required this.totalTransfer,
    required this.totalMixed,
    required this.totalOther,
    required this.totalTips,
    required this.totalExpenses,
    required this.paymentsCount,
    required this.ordersCount,
    required this.tablesCount,
    required this.averageTicket,
  });

  final DateTime businessDate;
  final double totalSold;
  final double totalCash;
  final double totalCard;
  final double totalTransfer;
  final double totalMixed;
  final double totalOther;
  final double totalTips;
  final double totalExpenses;
  final int paymentsCount;
  final int ordersCount;
  final int tablesCount;
  final double averageTicket;

  factory TodaySalesSummary.fromJson(Map<String, dynamic> json) =>
      TodaySalesSummary(
        businessDate:
            DateTime.tryParse(json['businessDate']?.toString() ?? '') ??
            DateTime.now(),
        totalSold: _asDouble(json['totalSold']),
        totalCash: _asDouble(json['totalCash']),
        totalCard: _asDouble(json['totalCard']),
        totalTransfer: _asDouble(json['totalTransfer']),
        totalMixed: _asDouble(json['totalMixed']),
        totalOther: _asDouble(json['totalOther']),
        totalTips: _asDouble(json['totalTips']),
        totalExpenses: _asDouble(json['totalExpenses']),
        paymentsCount: _asInt(json['paymentsCount']),
        ordersCount: _asInt(json['ordersCount']),
        tablesCount: _asInt(json['tablesCount']),
        averageTicket: _asDouble(json['averageTicket']),
      );
}

class TodaySale {
  TodaySale({
    required this.paymentId,
    required this.orderId,
    required this.tableId,
    required this.tableName,
    required this.paymentMethod,
    required this.subtotal,
    required this.total,
    required this.tip,
    required this.paidAt,
    required this.cashierName,
    required this.orderStatus,
    required this.selections,
  });

  final int paymentId;
  final int orderId;
  final int? tableId;
  final String tableName;
  final String paymentMethod;
  final double subtotal;
  final double total;
  final double? tip;
  final DateTime paidAt;
  final String? cashierName;
  final String orderStatus;
  final List<TodaySaleSelection> selections;

  bool get hasDetailAvailable => selections.isNotEmpty;

  String get paymentMethodLabel {
    switch (paymentMethod.trim().toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'mixed':
        return 'Mixto';
      case 'other':
        return 'Otro';
      default:
        return paymentMethod.trim().isEmpty ? 'Otro' : paymentMethod.trim();
    }
  }

  String get displayTableName {
    if (tableName.trim().isNotEmpty) {
      return tableName.trim();
    }

    if (tableId != null && tableId! > 0) {
      return 'Mesa $tableId';
    }

    return 'Mesa sin asignar';
  }

  factory TodaySale.fromJson(Map<String, dynamic> json) => TodaySale(
    paymentId: _asInt(json['paymentId']),
    orderId: _asInt(json['orderId']),
    tableId: _asNullableInt(json['tableId']),
    tableName: json['tableName']?.toString() ?? '',
    paymentMethod: json['paymentMethod']?.toString() ?? '',
    subtotal: _asDouble(json['subtotal']),
    total: _asDouble(json['total']),
    tip: _asNullableDouble(json['tip']),
    paidAt:
        DateTime.tryParse(json['paidAt']?.toString() ?? '') ?? DateTime.now(),
    cashierName: json['cashierName']?.toString(),
    orderStatus: json['orderStatus']?.toString() ?? '',
    selections: _readSelections(json),
  );
}

class TodaySaleSelection {
  TodaySaleSelection({
    required this.selectionId,
    required this.sequenceNumber,
    required this.label,
    required this.comment,
    required this.total,
    required this.items,
  });

  final int selectionId;
  final int sequenceNumber;
  final String label;
  final String? comment;
  final double total;
  final List<TodaySaleSelectionItem> items;

  String get displayLabel {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isNotEmpty) {
      return normalizedLabel;
    }

    if (sequenceNumber > 0) {
      return 'Seleccion $sequenceNumber';
    }

    return 'Seleccion';
  }

  String get displayComment => comment?.trim() ?? '';

  List<TodaySaleSelectionItem> get visibleItems =>
      items.where((item) => item.quantity > 0).toList(growable: false);

  factory TodaySaleSelection.fromJson(Map<String, dynamic> json) {
    final items = _readSelectionItems(json);

    return TodaySaleSelection(
      selectionId: _asInt(json['selectionId'] ?? json['id']),
      sequenceNumber: _asInt(
        json['sequenceNumber'] ??
            json['selectionSequenceNumber'] ??
            json['sequence'],
      ),
      label: _asString(
        json['label'] ?? json['selectionLabel'] ?? json['title'],
      ),
      comment: _firstNonEmptyString([
        json['comment'],
        json['notes'],
        json['selectionComment'],
      ]),
      total: _asDouble(
        json['total'] ??
            json['selectionTotal'] ??
            items.fold<double>(0, (sum, item) => sum + item.total),
      ),
      items: items,
    );
  }
}

class TodaySaleSelectionItem {
  TodaySaleSelectionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.role,
    required this.imageName,
    required this.sortOrder,
  });

  static const int mainRole = 1;
  static const int beverageRole = 2;
  static const int extraRole = 3;

  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;
  final int role;
  final String? imageName;
  final int sortOrder;

  String get displayName {
    final normalized = productName.trim();
    return normalized.isEmpty ? 'Producto no disponible' : normalized;
  }

  String get roleLabel {
    switch (role) {
      case beverageRole:
        return 'Bebida';
      case extraRole:
        return 'Extra';
      case mainRole:
      default:
        return 'Platillo principal';
    }
  }

  factory TodaySaleSelectionItem.fromJson(Map<String, dynamic> json) =>
      TodaySaleSelectionItem(
        productId: _asInt(json['productId'] ?? json['id']),
        productName: _asString(
          json['productName'] ?? json['name'] ?? json['label'],
        ),
        quantity: _asInt(json['quantity']),
        unitPrice: _asDouble(json['unitPrice'] ?? json['price']),
        total: _asDouble(json['total']),
        role: _parseRole(json['role']),
        imageName: _normalizedNullableString(
          json['imageName'] ?? json['image'] ?? json['productImageName'],
        ),
        sortOrder: _asInt(json['sortOrder'] ?? json['roleOrder']),
      );
}

List<TodaySaleSelection> _readSelections(Map<String, dynamic> json) {
  final order = _asMap(json['order']);
  final rawSelections =
      json['selections'] ?? json['orderSelections'] ?? order?['selections'];

  if (rawSelections is! List<dynamic>) {
    return const [];
  }

  return rawSelections
      .whereType<Map<String, dynamic>>()
      .map(TodaySaleSelection.fromJson)
      .toList(growable: false);
}

List<TodaySaleSelectionItem> _readSelectionItems(Map<String, dynamic> json) {
  final rawItems = json['items'] ?? json['selectionItems'];
  if (rawItems is! List<dynamic>) {
    return const [];
  }

  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(TodaySaleSelectionItem.fromJson)
      .toList(growable: false)
    ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

int? _asNullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

String _asString(Object? value) => value?.toString() ?? '';

String? _normalizedNullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

String? _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  return null;
}

int _parseRole(Object? value) {
  if (value is num) {
    final role = value.toInt();
    if (role >= TodaySaleSelectionItem.mainRole &&
        role <= TodaySaleSelectionItem.extraRole) {
      return role;
    }
  }

  final normalized = value?.toString().trim().toLowerCase() ?? '';
  switch (normalized) {
    case '1':
    case 'main':
    case 'principal':
    case 'platillo':
    case 'platillo principal':
      return TodaySaleSelectionItem.mainRole;
    case '2':
    case 'beverage':
    case 'drink':
    case 'bebida':
      return TodaySaleSelectionItem.beverageRole;
    case '3':
    case 'extra':
    default:
      return TodaySaleSelectionItem.extraRole;
  }
}
