import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/payments/create_payment_request.dart';
import '../models/payments/payment.dart';

class PaymentService {
  final _client = ApiClient.instance.dio;

  Future<Payment> payOrder(CreatePaymentRequest request) async {
    try {
      final response = await _client.post(ApiConstants.payOrder, data: request.toJson());
      return Payment.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
