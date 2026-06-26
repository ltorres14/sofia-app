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
  );
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
