import 'package:flutter/material.dart';

import '../../data/models/tables/restaurant_table.dart';
import '../../features/auth/views/pin_login_view.dart';
import '../../features/cash_cut/views/cash_cut_view.dart';
import '../../features/kitchen/views/kitchen_view.dart';
import '../../features/orders/views/order_view.dart';
import '../../features/payments/views/payment_view.dart';
import '../../features/tables/views/tables_view.dart';
import 'route_names.dart';

class AppRouter {
  static const String initialRoute = RouteNames.login;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const PinLoginView());
      case RouteNames.tables:
        return MaterialPageRoute(builder: (_) => const TablesView());
      case RouteNames.order:
        return MaterialPageRoute(
          builder: (_) => OrderView(table: settings.arguments! as RestaurantTable),
        );
      case RouteNames.kitchen:
        return MaterialPageRoute(builder: (_) => const KitchenView());
      case RouteNames.payments:
        return MaterialPageRoute(builder: (_) => const PaymentView());
      case RouteNames.cashCut:
        return MaterialPageRoute(builder: (_) => const CashCutView());
      default:
        return MaterialPageRoute(builder: (_) => const PinLoginView());
    }
  }
}
