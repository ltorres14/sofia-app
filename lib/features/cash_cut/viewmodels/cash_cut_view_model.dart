import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/cash_cut/cash_cut.dart';
import '../../../data/repositories/cash_cut_repository.dart';

class CashCutViewModel extends ChangeNotifier {
  CashCutViewModel({required CashCutRepository cashCutRepository})
    : _cashCutRepository = cashCutRepository;

  final CashCutRepository _cashCutRepository;

  CashCut? cashCut;
  bool isLoading = false;
  bool isClosing = false;
  String? errorMessage;
  String? actionErrorMessage;
  String? successMessage;

  bool get supportsCashCutClosing => _cashCutRepository.supportsCloseToday;
  bool get canCloseCashCut =>
      cashCut != null && !cashCut!.isClosed && !isLoading && !isClosing;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    clearActionStatus(notify: false);
    notifyListeners();
    try {
      cashCut = await _cashCutRepository.getToday();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> closeCashCut() async {
    if (isClosing) {
      return false;
    }

    if (cashCut == null) {
      actionErrorMessage =
          'Todavia no hay un resumen de corte cargado para intentar cerrarlo.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    if (cashCut!.isClosed) {
      actionErrorMessage = 'El corte del dia ya fue cerrado.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    if (!_cashCutRepository.supportsCloseToday) {
      actionErrorMessage = _cashCutRepository.closeTodayUnavailableMessage;
      successMessage = null;
      notifyListeners();
      return false;
    }

    isClosing = true;
    actionErrorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _cashCutRepository.closeToday();
      cashCut = await _cashCutRepository.getToday();
      successMessage = 'Corte del dia cerrado correctamente.';
      return true;
    } catch (error) {
      if (error is ApiException &&
          error.statusCode == 409 &&
          error.message == 'El corte del dia ya fue cerrado.') {
        await _refreshCashCutSummarySafely();
      }
      actionErrorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isClosing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCashCutSummarySafely() async {
    try {
      cashCut = await _cashCutRepository.getToday();
    } catch (_) {}
  }

  void clearActionStatus({bool notify = true}) {
    if (actionErrorMessage == null && successMessage == null) {
      return;
    }

    actionErrorMessage = null;
    successMessage = null;
    if (notify) {
      notifyListeners();
    }
  }
}
