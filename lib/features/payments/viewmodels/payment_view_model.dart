import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/cash_cut/cash_cut.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/payments/create_payment_request.dart';
import '../../../data/models/payments/payment.dart';
import '../../../data/models/payments/payment_method.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/cash_cut_repository.dart';
import '../../../data/repositories/payment_repository.dart';

class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({
    required PaymentRepository paymentRepository,
    required CashCutRepository cashCutRepository,
    required AuthRepository authRepository,
  }) : _paymentRepository = paymentRepository,
       _cashCutRepository = cashCutRepository,
       _authRepository = authRepository;

  final PaymentRepository _paymentRepository;
  final CashCutRepository _cashCutRepository;
  final AuthRepository _authRepository;

  bool isLoading = false;
  bool isPaying = false;
  bool isClosingCashCut = false;
  String? errorMessage;
  String? successMessage;
  PaymentMethod? selectedMethod;
  String comments = '';
  CashCut? cashCut;
  Order? activeOrder;
  Payment? lastPayment;
  int? selectedTableId;

  List<PaymentMethod> get availableMethods => PaymentMethod.values
      .where((method) => method.canUseForNewPayments)
      .toList(growable: false);

  bool get canConfirmPayment =>
      hasPayableOrder &&
      selectedMethod != null &&
      !isPaying &&
      !isClosingCashCut;

  bool get hasPayableOrder => activeOrder?.isPayable ?? false;

  bool get supportsCashCutClosing => _cashCutRepository.supportsCloseToday;

  bool get canCloseCashCut =>
      cashCut != null &&
      !cashCut!.isClosed &&
      !isLoading &&
      !isPaying &&
      !isClosingCashCut;

  Future<void> load({int? initialTableId}) async {
    isLoading = true;
    clearStatus(notify: false);
    _resetPaymentForm();
    selectedTableId = initialTableId;
    notifyListeners();

    try {
      await _refreshCashCutSummary();
      if (initialTableId != null && initialTableId > 0) {
        await _loadPayableOrder(tableId: initialTableId);
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectMethod(PaymentMethod method) {
    selectedMethod = method;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void updateComments(String value) {
    comments = value;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void clearStatus({bool notify = true}) {
    errorMessage = null;
    successMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> loadOrderByTable(int tableId) async {
    if (tableId <= 0) {
      errorMessage = 'Ingresa un numero de mesa valido.';
      successMessage = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    clearStatus(notify: false);
    _resetPaymentForm();
    selectedTableId = tableId;
    notifyListeners();

    try {
      await _loadPayableOrder(tableId: tableId);
    } catch (error) {
      _resetPaymentForm();
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> payCurrentOrder() async {
    final order = activeOrder;
    final userId = _authRepository.currentUser?.userId;
    final method = selectedMethod;

    if (order == null) {
      errorMessage = 'Carga una orden antes de registrar el pago.';
      successMessage = null;
      notifyListeners();
      return;
    }

    if (!order.isPayable) {
      errorMessage = 'No se puede pagar una orden vacia.';
      successMessage = null;
      selectedMethod = null;
      notifyListeners();
      return;
    }

    if (method == null) {
      errorMessage = 'Selecciona un metodo de pago.';
      successMessage = null;
      notifyListeners();
      return;
    }

    if (userId == null) {
      errorMessage = 'No se pudo identificar al usuario actual.';
      successMessage = null;
      notifyListeners();
      return;
    }

    isPaying = true;
    clearStatus(notify: false);
    notifyListeners();
    final request = CreatePaymentRequest(
      orderId: order.id,
      amount: order.total,
      method: method.value,
      comments: comments,
      userId: userId,
    );

    debugPrint('[PaymentViewModel] Preparing payOrder request');
    debugPrint('[PaymentViewModel] orderId: ${request.orderId}');
    debugPrint('[PaymentViewModel] amount: ${request.amount}');
    debugPrint('[PaymentViewModel] method: ${request.method}');
    debugPrint('[PaymentViewModel] comments: "${request.comments ?? ''}"');
    debugPrint('[PaymentViewModel] userId: ${request.userId}');

    try {
      lastPayment = await _paymentRepository.payOrder(request);
      final tableName = order.tableName.trim();
      final tableLabel = tableName.isNotEmpty
          ? tableName
          : (order.tableId > 0 ? 'Mesa ${order.tableId}' : '');
      successMessage = tableLabel.isNotEmpty
          ? 'Pago registrado para $tableLabel · Orden #${order.id}'
          : 'Pago registrado para la orden #${order.id}';
      _resetPaymentForm();
      await _refreshCashCutSummary();
    } catch (error, stackTrace) {
      debugPrint('[PaymentViewModel] payCurrentOrder error: $error');
      debugPrint('[PaymentViewModel] payCurrentOrder stackTrace:\n$stackTrace');
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isPaying = false;
      notifyListeners();
    }
  }

  Future<bool> closeCashCut() async {
    if (isClosingCashCut) {
      return false;
    }

    if (cashCut == null) {
      errorMessage =
          'Todavia no hay un resumen de corte cargado para intentar cerrarlo.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    if (cashCut!.isClosed) {
      errorMessage = 'El corte del dia ya fue cerrado.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    if (!_cashCutRepository.supportsCloseToday) {
      errorMessage = _cashCutRepository.closeTodayUnavailableMessage;
      successMessage = null;
      notifyListeners();
      return false;
    }

    isClosingCashCut = true;
    clearStatus(notify: false);
    notifyListeners();

    try {
      await _cashCutRepository.closeToday();
      await _refreshCashCutSummary();
      successMessage = 'Corte del dia cerrado correctamente.';
      return true;
    } catch (error) {
      if (error is ApiException &&
          error.statusCode == 409 &&
          error.message == 'El corte del dia ya fue cerrado.') {
        await _refreshCashCutSummarySafely();
      }
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isClosingCashCut = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCashCutSummary() async {
    cashCut = await _cashCutRepository.getToday();
  }

  Future<void> _refreshCashCutSummarySafely() async {
    try {
      await _refreshCashCutSummary();
    } catch (_) {}
  }

  Future<void> _loadPayableOrder({required int tableId}) async {
    final order = await _paymentRepository.getPayableOrderByTable(tableId);

    if (order == null || !order.isPayable) {
      errorMessage = 'No hay una orden pendiente de cobro para esta mesa.';
      activeOrder = null;
      return;
    }

    activeOrder = order;
  }

  void _resetPaymentForm() {
    activeOrder = null;
    selectedMethod = null;
    comments = '';
  }
}
