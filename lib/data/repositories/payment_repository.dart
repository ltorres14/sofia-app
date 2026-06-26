import '../models/orders/order.dart';
import '../models/payments/create_payment_request.dart';
import '../models/payments/payment.dart';
import '../services/payment_service.dart';

class PaymentRepository {
  PaymentRepository({PaymentService? service})
    : _service = service ?? PaymentService();

  final PaymentService _service;

  Future<Order?> getPayableOrderByTable(int tableId) =>
      _service.getPayableOrderByTable(tableId);

  Future<Payment> payOrder(CreatePaymentRequest request) =>
      _service.payOrder(request);
}
