class RestaurantTable {
  RestaurantTable({
    required this.id,
    required this.name,
    required this.status,
    required this.isActive,
  });

  final int id;
  final String name;
  final int status;
  final bool isActive;

  bool get isFree => status == 1;
  bool get hasOrder => status == 2;
  bool get waitingPayment => status == 3;

  factory RestaurantTable.fromJson(Map<String, dynamic> json) => RestaurantTable(
        id: json['id'] as int,
        name: json['name'] as String,
        status: json['status'] as int,
        isActive: json['isActive'] as bool? ?? true,
      );
}
