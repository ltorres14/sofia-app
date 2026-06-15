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

  String _extractServerMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final directMessage = data['message']?.toString();
      if (directMessage != null && directMessage.trim().isNotEmpty) {
        return directMessage;
      }

      final title = data['title']?.toString();
      if (title != null && title.trim().isNotEmpty) {
        return title;
      }

      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final messages = errors.values
            .expand(
              (value) => value is Iterable
                  ? value.map((item) => item.toString())
                  : [value.toString()],
            )
            .where((item) => item.trim().isNotEmpty)
            .toList();

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return '';
  }

  Never parseError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final backendMessage = _extractServerMessage(error.response?.data);

      if (statusCode == 401) {
        throw ApiException(
          'Tu sesión expiró. Inicia sesión otra vez.',
          statusCode: 401,
        );
      }

      if (statusCode == 500) {
        throw ApiException(
          backendMessage.isNotEmpty
              ? backendMessage
              : 'El servidor devolvió un error interno (500).',
          statusCode: statusCode,
        );
      }

      if (statusCode != null) {
        throw ApiException(
          backendMessage.isNotEmpty
              ? backendMessage
              : 'La API respondió con error HTTP $statusCode.',
          statusCode: statusCode,
        );
      }

      throw ApiException(
        backendMessage.isNotEmpty
            ? backendMessage
            : 'No se pudo conectar con la API.',
      );
    }

    throw ApiException('Ocurrió un error inesperado.');
  }
}
