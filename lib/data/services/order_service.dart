import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/orders/order.dart';

class CreateOrderSelectionItemRequest {
  CreateOrderSelectionItemRequest({
    required this.productId,
    required this.quantity,
    required this.role,
    required this.sortOrder,
    this.notes,
  });

  final int productId;
  final int quantity;
  final int role;
  final int sortOrder;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'role': role,
    'notes': notes ?? '',
    'sortOrder': sortOrder,
  };
}

class OrderService {
  final _client = ApiClient.instance.dio;

  Future<Order?> getOpenOrderByTable(int tableId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.orders}/table/$tableId',
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      if (error is Exception) {
        try {
          ApiClient.instance.parseError(error);
        } catch (_) {
          return null;
        }
      }
      rethrow;
    }
  }

  Future<Order> addItem({
    required int orderId,
    required int productId,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConstants.orders}/$orderId/items',
        data: {'productId': productId, 'quantity': quantity, 'notes': notes},
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<Order> addSelection({
    required int orderId,
    required String label,
    String? notes,
    required List<CreateOrderSelectionItemRequest> items,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConstants.orders}/$orderId/selections',
        data: {
          'label': label,
          'notes': notes ?? '',
          'items': items.map((item) => item.toJson()).toList(),
        },
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<void> sendToKitchen(int orderId) async {
    try {
      await _client.post('${ApiConstants.orders}/$orderId/send-to-kitchen');
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
