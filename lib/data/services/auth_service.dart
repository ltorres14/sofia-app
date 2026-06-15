import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/auth/current_user.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/auth/offline_user.dart';

class AuthService {
  final _client = ApiClient.instance.dio;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _client.post(ApiConstants.authPin, data: request.toJson());
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<CurrentUser> getCurrentUser() async {
    try {
      final response = await _client.get(ApiConstants.authMe);
      return CurrentUser.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<List<OfflineUser>> getOfflineUsers() async {
    try {
      final response = await _client.get(ApiConstants.offlineUsers);
      return (response.data as List<dynamic>)
          .map((item) => OfflineUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
