import '../config/api_config.dart';

class ApiConstants {
  static String get baseUrl => ApiConfig.baseUrl;

  static const String authPin = '/api/auth/pin';
  static const String authMe = '/api/auth/me';
  static const String offlineUsers = '/api/auth/offline-users';
  static const String tables = '/api/tables';
  static const String products = '/api/products';
  static const String orders = '/api/orders';
  static const String kitchenTickets = '/api/kitchen/tickets';
  static const String payOrder = '/api/payments/pay-order';
  static const String cashCutToday = '/api/cashcut/today';
}
