import 'package:flutter/material.dart';

import '../../../data/models/cash_cut/cash_cut.dart';
import '../../../data/repositories/cash_cut_repository.dart';

class CashCutViewModel extends ChangeNotifier {
  CashCutViewModel({required CashCutRepository cashCutRepository})
      : _cashCutRepository = cashCutRepository;

  final CashCutRepository _cashCutRepository;

  CashCut? cashCut;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
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
}
