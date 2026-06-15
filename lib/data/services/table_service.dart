import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/orders/create_order_request.dart';
import '../models/orders/order.dart';
import '../models/tables/restaurant_table.dart';

class TableService {
  final _client = ApiClient.instance.dio;

  Future<List<RestaurantTable>> getTables() async {
    try {
      final response = await _client.get(ApiConstants.tables);
      return (response.data as List<dynamic>)
          .map((item) => RestaurantTable.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<Order> openTable(int tableId, CreateOrderRequest request) async {
    try {
      final response = await _client.post(
        '${ApiConstants.tables}/$tableId/open',
        data: request.toJson(),
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
