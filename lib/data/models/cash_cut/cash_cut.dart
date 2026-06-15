class CashCut {
  CashCut({
    required this.id,
    required this.businessDate,
    required this.totalCash,
    required this.totalCard,
    required this.totalTransfer,
    required this.totalMixed,
    required this.grandTotal,
    required this.calculatedAt,
  });

  final int id;
  final DateTime businessDate;
  final double totalCash;
  final double totalCard;
  final double totalTransfer;
  final double totalMixed;
  final double grandTotal;
  final DateTime calculatedAt;

  double get tips => 0;
  double get expenses => 0;

  factory CashCut.fromJson(Map<String, dynamic> json) => CashCut(
        id: json['id'] as int? ?? 0,
        businessDate: DateTime.parse(json['businessDate'] as String),
        totalCash: (json['totalCash'] as num).toDouble(),
        totalCard: (json['totalCard'] as num).toDouble(),
        totalTransfer: (json['totalTransfer'] as num).toDouble(),
        totalMixed: (json['totalMixed'] as num).toDouble(),
        grandTotal: (json['grandTotal'] as num).toDouble(),
        calculatedAt: DateTime.tryParse(json['calculatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
