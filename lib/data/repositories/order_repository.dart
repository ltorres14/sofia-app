import '../models/orders/order.dart';
import '../services/order_service.dart';

class OrderRepository {
  OrderRepository({OrderService? service}) : _service = service ?? OrderService();

  final OrderService _service;

  Future<Order?> getOpenOrderByTable(int tableId) => _service.getOpenOrderByTable(tableId);

  Future<void> addItem({
    required int orderId,
    required int productId,
    int quantity = 1,
    String? notes,
  }) {
    return _service.addItem(
      orderId: orderId,
      productId: productId,
      quantity: quantity,
      notes: notes,
    );
  }

  Future<void> sendToKitchen(int orderId) => _service.sendToKitchen(orderId);
}
