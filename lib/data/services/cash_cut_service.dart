import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/cash_cut/cash_cut.dart';
import '../models/cash_cut/today_sales.dart';

class CashCutService {
  final _client = ApiClient.instance.dio;

  static const String closeTodayUnavailableMessage =
      'El cierre de corte del dia no esta disponible.';

  bool get supportsCloseToday => true;

  Future<CashCut> getToday() async {
    try {
      final response = await _client.get(ApiConstants.cashCutToday);
      return CashCut.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<TodaySalesResponse> getTodaySales() async {
    try {
      final response = await _client.get(ApiConstants.cashCutTodaySales);
      return TodaySalesResponse.fromJson(response.data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<CashCut> closeToday() async {
    try {
      final response = await _client.post(ApiConstants.cashCutCloseToday);
      return CashCut.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      final backendMessage = _extractMessage(responseData).toLowerCase();

      if (statusCode == 401) {
        throw ApiException(
          'Tu sesion expiro. Inicia sesion otra vez.',
          statusCode: 401,
        );
      }

      if (statusCode == 403) {
        throw ApiException(
          'No tienes permisos para cerrar el corte del dia.',
          statusCode: 403,
        );
      }

      if (statusCode == 409) {
        if (_hasAlreadyClosedError(responseData, backendMessage)) {
          throw ApiException(
            'El corte del dia ya fue cerrado.',
            statusCode: 409,
          );
        }

        if (_hasPendingOrdersError(responseData, backendMessage)) {
          throw ApiException(
            'No se puede cerrar el corte porque hay ordenes pendientes de pago.',
            statusCode: 409,
          );
        }

        if (_hasNoPaymentsError(backendMessage)) {
          throw ApiException(
            'No hay pagos registrados para cerrar el corte.',
            statusCode: 409,
          );
        }
      }

      if (statusCode == 400) {
        final message = _extractMessage(responseData);
        throw ApiException(
          message.isNotEmpty ? message : 'No se pudo cerrar el corte del dia.',
          statusCode: 400,
        );
      }

      ApiClient.instance.parseError(error);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  String _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return '';
  }

  bool _hasAlreadyClosedError(Object? data, String backendMessage) {
    if (data is Map<String, dynamic> && data['cashCut'] != null) {
      return true;
    }

    return backendMessage.contains('ya fue cerrado');
  }

  bool _hasPendingOrdersError(Object? data, String backendMessage) {
    if (data is Map<String, dynamic> && data['pendingPayableOrders'] != null) {
      return true;
    }

    return backendMessage.contains('pendientes de pago');
  }

  bool _hasNoPaymentsError(String backendMessage) {
    return backendMessage.contains('no existen pagos') ||
        backendMessage.contains('no hay pagos');
  }
}
