import '../models/orders/create_order_request.dart';
import '../models/orders/order.dart';
import '../models/tables/restaurant_table.dart';
import '../services/table_service.dart';

class TableRepository {
  TableRepository({TableService? service}) : _service = service ?? TableService();

  final TableService _service;

  Future<List<RestaurantTable>> getTables() => _service.getTables();

  Future<Order> openTable(int tableId, int userId) {
    return _service.openTable(tableId, CreateOrderRequest(userId: userId));
  }
}
