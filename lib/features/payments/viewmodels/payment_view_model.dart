import 'package:flutter/material.dart';

import '../../../data/models/cash_cut/cash_cut.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/payments/create_payment_request.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/cash_cut_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/payment_repository.dart';

class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({
    required PaymentRepository paymentRepository,
    required CashCutRepository cashCutRepository,
    required OrderRepository orderRepository,
    required AuthRepository authRepository,
  })  : _paymentRepository = paymentRepository,
        _cashCutRepository = cashCutRepository,
        _orderRepository = orderRepository,
        _authRepository = authRepository;

  final PaymentRepository _paymentRepository;
  final CashCutRepository _cashCutRepository;
  final OrderRepository _orderRepository;
  final AuthRepository _authRepository;

  bool isLoading = false;
  String? errorMessage;
  int selectedMethod = 1;
  CashCut? cashCut;
  Order? activeOrder;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cashCut = await _cashCutRepository.getToday();
      activeOrder = null;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectMethod(int method) {
    selectedMethod = method;
    notifyListeners();
  }

  Future<void> loadOrderByTable(int tableId) async {
    isLoading = true;
    notifyListeners();
    try {
      activeOrder = await _orderRepository.getOpenOrderByTable(tableId);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> payCurrentOrder() async {
    final order = activeOrder;
    final userId = _authRepository.currentUser?.userId;
    if (order == null || userId == null) return;

    isLoading = true;
    notifyListeners();
    try {
      await _paymentRepository.payOrder(
        CreatePaymentRequest(
          orderId: order.id,
          amount: order.total,
          method: selectedMethod,
          userId: userId,
        ),
      );
      activeOrder = null;
      cashCut = await _cashCutRepository.getToday();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
