import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    )..interceptors.add(AuthInterceptor());
  }

  late final Dio _dio;

  static final ApiClient instance = ApiClient._internal();

  Dio get dio => _dio;

  Never parseError(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        throw ApiException('Tu sesión expiró. Inicia sesión otra vez.', statusCode: 401);
      }
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['message']?.toString() ?? 'Ocurrió un error con el servidor.')
          : 'No se pudo conectar con la API.';
      throw ApiException(message, statusCode: error.response?.statusCode);
    }
    throw ApiException('Ocurrió un error inesperado.');
  }
}
