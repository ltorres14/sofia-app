class CreateOrderRequest {
  CreateOrderRequest({required this.userId});

  final int userId;

  Map<String, dynamic> toJson() => {'userId': userId};
}
