import '../constants/role_constants.dart';
import 'route_names.dart';

class RouteAccess {
  static bool canAccess({required String? role, required String routeName}) {
    if (routeName == RouteNames.login) {
      return true;
    }

    if (role == null || role.isEmpty) {
      return false;
    }

    switch (routeName) {
      case RouteNames.tables:
      case RouteNames.order:
        return role == RoleConstants.waiter || role == RoleConstants.cashier;
      case RouteNames.kitchen:
        return role == RoleConstants.kitchen || role == RoleConstants.cashier;
      case RouteNames.payments:
      case RouteNames.cashCut:
      case RouteNames.todaySales:
        return role == RoleConstants.cashier;
      default:
        return false;
    }
  }

  static String defaultRouteForRole(String? role) {
    if (role == RoleConstants.waiter) {
      return RouteNames.tables;
    }
    if (role == RoleConstants.kitchen) {
      return RouteNames.kitchen;
    }
    if (role == RoleConstants.cashier) {
      return RouteNames.payments;
    }
    return RouteNames.login;
  }
}
