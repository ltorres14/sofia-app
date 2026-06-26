import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/orders/order.dart';
import '../models/payments/create_payment_request.dart';
import '../models/payments/payment.dart';

class PaymentService {
  final _client = ApiClient.instance.dio;

  Future<Order?> getPayableOrderByTable(int tableId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.paymentOrderByTable}/$tableId',
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 404) {
        return null;
      }

      ApiClient.instance.parseError(error);
    }
  }

  Future<Payment> payOrder(CreatePaymentRequest request) async {
    final payload = request.toJson();

    debugPrint('[PaymentService] POST endpoint: ${ApiConstants.payOrder}');
    debugPrint('[PaymentService] POST body: $payload');

    try {
      final response = await _client.post(ApiConstants.payOrder, data: payload);
      debugPrint(
        '[PaymentService] Response statusCode: ${response.statusCode}',
      );
      debugPrint('[PaymentService] Response body: ${response.data}');
      return Payment.fromJson(response.data as Map<String, dynamic>);
    } catch (error, stackTrace) {
      debugPrint('[PaymentService] payOrder error: $error');
      debugPrint('[PaymentService] payOrder stackTrace:\n$stackTrace');
      if (error is DioException) {
        debugPrint(
          '[PaymentService] DioException statusCode: ${error.response?.statusCode}',
        );
        debugPrint(
          '[PaymentService] DioException response body: ${error.response?.data}',
        );
      }
      ApiClient.instance.parseError(error);
    }
  }
}
