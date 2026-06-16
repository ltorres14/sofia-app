import 'package:flutter/material.dart';

import '../../data/models/tables/restaurant_table.dart';
import '../../features/auth/views/pin_login_view.dart';
import '../../features/cash_cut/views/cash_cut_view.dart';
import '../../features/kitchen/views/kitchen_view.dart';
import '../../features/orders/views/order_view.dart';
import '../../features/payments/views/payment_view.dart';
import '../../features/tables/views/tables_view.dart';
import '../../shared/layouts/pos_shell.dart';
import 'protected_route_page.dart';
import 'route_names.dart';

class AppRouter {
  static const String initialRoute = RouteNames.login;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const PinLoginView());
      case RouteNames.tables:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRoutePage(
            routeName: RouteNames.tables,
            child: PosShell(
              title: 'SOFIA Check',
              subtitle: 'Mesas del turno',
              currentRoute: RouteNames.tables,
              child: TablesView(),
            ),
          ),
        );
      case RouteNames.order:
        return MaterialPageRoute(
          builder: (context) => ProtectedRoutePage(
            routeName: RouteNames.order,
            child: PosShell(
              title: 'SOFIA Check',
              subtitle: 'Toma de orden',
              currentRoute: RouteNames.order,
              trailing: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE8DDCC),
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFFB7791F),
                  size: 22,
                ),
              ),
              child: OrderView(table: settings.arguments! as RestaurantTable),
            ),
          ),
        );
      case RouteNames.kitchen:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRoutePage(
            routeName: RouteNames.kitchen,
            child: PosShell(
              title: 'SOFIA Check',
              subtitle: 'Comandas en cocina',
              currentRoute: RouteNames.kitchen,
              child: KitchenView(),
            ),
          ),
        );
      case RouteNames.payments:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRoutePage(
            routeName: RouteNames.payments,
            child: PosShell(
              title: 'Caja',
              subtitle: 'Cobros y resumen del día',
              currentRoute: RouteNames.payments,
              child: PaymentView(),
            ),
          ),
        );
      case RouteNames.cashCut:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRoutePage(
            routeName: RouteNames.cashCut,
            child: PosShell(
              title: 'Corte del día',
              subtitle: 'Resumen de caja',
              currentRoute: RouteNames.cashCut,
              child: CashCutView(),
            ),
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const PinLoginView());
    }
  }
}
