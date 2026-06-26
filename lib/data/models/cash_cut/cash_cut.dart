class CashCut {
  CashCut({
    required this.id,
    required this.businessDate,
    required this.totalCash,
    required this.totalCard,
    required this.totalTransfer,
    required this.totalMixed,
    required this.totalOther,
    required this.totalTips,
    required this.totalExpenses,
    required this.grandTotal,
    required this.closedAt,
    required this.calculatedAt,
  });

  final int id;
  final DateTime businessDate;
  final double totalCash;
  final double totalCard;
  final double totalTransfer;
  final double totalMixed;
  final double totalOther;
  final double totalTips;
  final double totalExpenses;
  final double grandTotal;
  final DateTime? closedAt;
  final DateTime calculatedAt;

  double get tips => totalTips;
  double get expenses => totalExpenses;
  bool get isClosed => closedAt != null;

  factory CashCut.fromJson(Map<String, dynamic> json) => CashCut(
    id: json['id'] as int? ?? 0,
    businessDate: DateTime.parse(json['businessDate'] as String),
    totalCash: (json['totalCash'] as num).toDouble(),
    totalCard: (json['totalCard'] as num).toDouble(),
    totalTransfer: (json['totalTransfer'] as num).toDouble(),
    totalMixed: (json['totalMixed'] as num?)?.toDouble() ?? 0,
    totalOther: (json['totalOther'] as num?)?.toDouble() ?? 0,
    totalTips: (json['totalTips'] as num?)?.toDouble() ?? 0,
    totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0,
    grandTotal: (json['grandTotal'] as num).toDouble(),
    closedAt: DateTime.tryParse(json['closedAt']?.toString() ?? ''),
    calculatedAt:
        DateTime.tryParse(json['calculatedAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}
