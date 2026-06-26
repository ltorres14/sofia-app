import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/routing/route_access.dart';
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

  String _maskPin(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) return '*';
    return '${value.substring(0, 1)}${List.filled(value.length - 1, '*').join()}';
  }

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
    debugPrint(
      '[LoginViewModel] login start baseUrl: ${ApiConfig.baseUrl} endpoint: ${ApiConstants.authPin}',
    );
    debugPrint(
      '[LoginViewModel] login pinLength: ${pin.length} maskedPin: ${_maskPin(pin)}',
    );

    final validation = Validators.pin(pin);
    if (validation != null) {
      errorMessage = validation;
      debugPrint('[LoginViewModel] validationError: $errorMessage');
      notifyListeners();
      return null;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(pin);
      debugPrint(
        '[LoginViewModel] login success role: ${response.user.role} expiresAt: ${response.expiresAt.toIso8601String()}',
      );
      return RouteAccess.defaultRouteForRole(response.user.role);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      debugPrint('[LoginViewModel] login caughtError: $error');
      debugPrint('[LoginViewModel] login userErrorMessage: $errorMessage');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
