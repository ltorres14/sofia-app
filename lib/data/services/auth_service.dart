import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/auth/current_user.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/auth/offline_user.dart';

class AuthService {
  final _client = ApiClient.instance.dio;

  String _maskPin(String pin) {
    if (pin.isEmpty) return pin;
    if (pin.length <= 2) return '${pin[0]}*';
    return '${pin.substring(0, 2)}${List.filled(pin.length - 2, '*').join()}';
  }

  void _logRequest({
    required String action,
    required String endpoint,
    Map<String, dynamic>? body,
  }) {
    debugPrint('[AuthService] $action baseUrl: ${_client.options.baseUrl}');
    debugPrint('[AuthService] $action endpoint: $endpoint');
    if (body != null) {
      debugPrint('[AuthService] $action body: $body');
    }
  }

  void _logResponse({
    required String action,
    required Response<dynamic> response,
  }) {
    debugPrint('[AuthService] $action requestUri: ${response.requestOptions.uri}');
    debugPrint('[AuthService] $action statusCode: ${response.statusCode}');
    debugPrint('[AuthService] $action responseBody: ${response.data}');
  }

  void _logDioError({
    required String action,
    required DioException error,
  }) {
    debugPrint('[AuthService] $action requestUri: ${error.requestOptions.uri}');
    debugPrint('[AuthService] $action dioType: ${error.type}');
    debugPrint('[AuthService] $action dioMessage: ${error.message}');
    debugPrint(
      '[AuthService] $action dioStatusCode: ${error.response?.statusCode}',
    );
    debugPrint('[AuthService] $action dioResponseBody: ${error.response?.data}');
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final requestBody = {'pin': _maskPin(request.pin)};
    _logRequest(
      action: 'login',
      endpoint: ApiConstants.authPin,
      body: requestBody,
    );

    try {
      final response = await _client.post(
        ApiConstants.authPin,
        data: request.toJson(),
      );
      _logResponse(action: 'login', response: response);
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      _logDioError(action: 'login', error: error);
      ApiClient.instance.parseError(error);
    } catch (error) {
      debugPrint('[AuthService] login unexpectedError: $error');
      ApiClient.instance.parseError(error);
    }
  }

  Future<CurrentUser> getCurrentUser() async {
    _logRequest(action: 'getCurrentUser', endpoint: ApiConstants.authMe);

    try {
      final response = await _client.get(ApiConstants.authMe);
      _logResponse(action: 'getCurrentUser', response: response);
      return CurrentUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      _logDioError(action: 'getCurrentUser', error: error);
      ApiClient.instance.parseError(error);
    } catch (error) {
      debugPrint('[AuthService] getCurrentUser unexpectedError: $error');
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
