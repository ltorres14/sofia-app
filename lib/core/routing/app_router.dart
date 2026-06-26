import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/tables/restaurant_table.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/views/pin_login_view.dart';
import '../../features/cash_cut/views/cash_cut_view.dart';
import '../../features/cash_cut/views/today_sales_view.dart';
import '../../features/kitchen/views/kitchen_view.dart';
import '../../features/orders/views/order_view.dart';
import '../../features/payments/views/payment_view.dart';
import '../../features/tables/viewmodels/tables_view_model.dart';
import '../../features/tables/views/tables_view.dart';
import '../../shared/layouts/pos_shell.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../theme/app_colors.dart';
import 'protected_route_page.dart';
import 'route_access.dart';
import 'route_names.dart';

class AppRouter {
  static const String initialRoute = RouteNames.login;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const PinLoginView());
      case RouteNames.tables:
        return MaterialPageRoute(
          builder: (_) => ProtectedRoutePage(
            routeName: RouteNames.tables,
            child: Consumer<TablesViewModel>(
              builder: (context, viewModel, child) {
                return LoadingOverlay(
                  loading: viewModel.isLoading,
                  child: child!,
                );
              },
              child: const PosShell(
                title: 'SOFIA Check',
                subtitle: 'Mesas del turno',
                currentRoute: RouteNames.tables,
                child: TablesView(),
              ),
            ),
          ),
        );
      case RouteNames.order:
        return MaterialPageRoute(
          builder: (context) {
            final table = settings.arguments! as RestaurantTable;
            final role = context.read<AuthRepository>().currentUser?.role;
            final canAccessPayments = RouteAccess.canAccess(
              role: role,
              routeName: RouteNames.payments,
            );

            return ProtectedRoutePage(
              routeName: RouteNames.order,
              child: PosShell(
                title: 'SOFIA Check',
                subtitle: 'Toma de orden',
                currentRoute: RouteNames.order,
                trailing: canAccessPayments
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed(
                              RouteNames.payments,
                              arguments: table.id,
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.secondary),
                            ),
                            child: Icon(
                              Icons.point_of_sale_rounded,
                              color: AppColors.secondary,
                              size: 22,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.secondary),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
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
