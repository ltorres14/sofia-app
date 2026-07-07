import 'package:flutter/material.dart';

import '../../data/models/tables/restaurant_table.dart';
import '../../features/auth/views/pin_login_view.dart';
import '../../features/cash_cut/views/cash_cut_view.dart';
import '../../features/cash_cut/views/today_sales_view.dart';
import '../../features/kitchen/views/kitchen_view.dart';
import '../../features/orders/views/order_view.dart';
import '../../features/payments/views/payment_view.dart';
import '../../features/tables/views/tables_view.dart';
import '../../shared/layouts/pos_shell.dart';
import '../theme/app_colors.dart';
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
          builder: (context) {
            final table = settings.arguments! as RestaurantTable;

            return ProtectedRoutePage(
              routeName: RouteNames.order,
              child: PosShell(
                title: 'SOFIA Check',
                subtitle: 'Toma de orden - ${table.name}',
                currentRoute: RouteNames.order,

                /// Botón de regreso
                leading: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.35),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                /// Ya no mostramos botón derecho
                trailing: null,

                child: OrderView(table: table),
              ),
            );
          },
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
        final initialTableId = settings.arguments is int
            ? settings.arguments! as int
            : null;

        return MaterialPageRoute(
          builder: (_) => ProtectedRoutePage(
            routeName: RouteNames.payments,
            child: PosShell(
              title: 'Caja',
              subtitle: 'Cobros y resumen del dia',
              currentRoute: RouteNames.payments,
              child: PaymentView(initialTableId: initialTableId),
            ),
          ),
        );

      case RouteNames.cashCut:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRoutePage(
            routeName: RouteNames.cashCut,
            child: PosShell(
              title: 'Corte del dia',
              subtitle: 'Resumen de caja',
              currentRoute: RouteNames.cashCut,
              child: CashCutView(),
            ),
          ),
        );

      case RouteNames.todaySales:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRoutePage(
            routeName: RouteNames.todaySales,
            child: PosShell(
              title: 'Ventas del dia',
              subtitle: 'Ventas del dia',
              currentRoute: RouteNames.todaySales,
              child: TodaySalesView(),
            ),
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const PinLoginView());
    }
  }
}
