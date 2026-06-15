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

  Future<LoginResponse> login(String pin) async {
    final result = await _service.login(LoginRequest(pin: pin));
    await SecureStorageService.saveToken(result.token);
    currentUser = await _service.getCurrentUser();
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
