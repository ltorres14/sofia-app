import 'package:flutter/foundation.dart';

import '../../core/storage/secure_storage_service.dart';
import '../models/auth/current_user.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/auth/offline_user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;
  CurrentUser? currentUser;

  String _maskPin(String pin) {
    if (pin.isEmpty) return pin;
    if (pin.length == 1) return '*';
    return '${pin.substring(0, 1)}${List.filled(pin.length - 1, '*').join()}';
  }

  Future<LoginResponse> login(String pin) async {
    debugPrint(
      '[AuthRepository] login start pinLength: ${pin.length} maskedPin: ${_maskPin(pin)}',
    );
    final result = await _service.login(LoginRequest(pin: pin));
    debugPrint(
      '[AuthRepository] login success tokenLength: ${result.token.length} role: ${result.user.role}',
    );
    await SecureStorageService.saveToken(result.token);
    debugPrint('[AuthRepository] token saved, requesting current user');
    currentUser = await _service.getCurrentUser();
    debugPrint(
      '[AuthRepository] current user loaded: ${currentUser?.name} role: ${currentUser?.role}',
    );
    return result;
  }

  Future<CurrentUser?> restoreUser() async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    currentUser = await _service.getCurrentUser();
    return currentUser;
  }

  Future<List<OfflineUser>> getOfflineUsers() => _service.getOfflineUsers();

  Future<void> logout() async {
    currentUser = null;
    await SecureStorageService.clearToken();
  }
}
