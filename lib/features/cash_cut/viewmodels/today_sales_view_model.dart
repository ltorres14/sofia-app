import 'package:flutter/material.dart';

import '../../../data/models/cash_cut/today_sales.dart';
import '../../../data/repositories/cash_cut_repository.dart';

class TodaySalesViewModel extends ChangeNotifier {
  TodaySalesViewModel({required CashCutRepository cashCutRepository})
    : _cashCutRepository = cashCutRepository;

  final CashCutRepository _cashCutRepository;

  TodaySalesResponse? todaySales;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    if (isLoading) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      todaySales = await _cashCutRepository.getTodaySales();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
