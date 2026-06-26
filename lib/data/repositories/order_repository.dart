import '../models/orders/order.dart';
import '../services/order_service.dart';

class OrderRepository {
  OrderRepository({OrderService? service})
    : _service = service ?? OrderService();

  final OrderService _service;

  Future<Order?> getOpenOrderByTable(int tableId) =>
      _service.getOpenOrderByTable(tableId);

  Future<Order> addItem({
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

  Future<Order> addSelection({
    required int orderId,
    required String label,
    String? notes,
    required List<CreateOrderSelectionItemRequest> items,
  }) {
    return _service.addSelection(
      orderId: orderId,
      label: label,
      notes: notes,
      items: items,
    );
  }

  Future<void> sendToKitchen(int orderId) => _service.sendToKitchen(orderId);

  Future<void> requestBill(int orderId) => _service.requestBill(orderId);
}
