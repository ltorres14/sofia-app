import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';

class PinLoginViewModel extends ChangeNotifier {
  PinLoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  String pin = '';
  bool isLoading = false;
  String? errorMessage;
  bool _shouldAutoSubmit = false;

  void appendDigit(String digit) {
    if (pin.length >= AppConstants.pinLength || isLoading) return;
    pin += digit;
    errorMessage = null;
    if (pin.length == AppConstants.pinLength) {
      _shouldAutoSubmit = true;
    }
    notifyListeners();
  }

  void updatePin(String value) {
    if (isLoading) return;
    pin = value.length > AppConstants.pinLength
        ? value.substring(0, AppConstants.pinLength)
        : value;
    errorMessage = null;
    _shouldAutoSubmit = pin.length == AppConstants.pinLength;
    notifyListeners();
  }

  void backspace() {
    if (pin.isEmpty || isLoading) return;
    pin = pin.substring(0, pin.length - 1);
    _shouldAutoSubmit = false;
    notifyListeners();
  }

  void clear() {
    if (isLoading) return;
    pin = '';
    errorMessage = null;
    _shouldAutoSubmit = false;
    notifyListeners();
  }

  bool consumeAutoSubmit() {
    if (!_shouldAutoSubmit) return false;
    _shouldAutoSubmit = false;
    return true;
  }

  Future<String?> login() async {
    final validation = Validators.pin(pin);
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return null;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(pin);
      final role = response.user.role;
      if (role == RoleConstants.waiter) return RouteNames.tables;
      if (role == RoleConstants.kitchen) return RouteNames.kitchen;
      return RouteNames.payments;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
