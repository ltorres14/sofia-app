import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cash_cut_repository.dart';
import 'data/repositories/kitchen_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/table_repository.dart';
import 'features/auth/viewmodels/pin_login_view_model.dart';
import 'features/cash_cut/viewmodels/cash_cut_view_model.dart';
import 'features/kitchen/viewmodels/kitchen_view_model.dart';
import 'features/orders/viewmodels/order_view_model.dart';
import 'features/payments/viewmodels/payment_view_model.dart';
import 'features/tables/viewmodels/tables_view_model.dart';

class SofiaApp extends StatelessWidget {
  const SofiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => TableRepository()),
        Provider(create: (_) => ProductRepository()),
        Provider(create: (_) => OrderRepository()),
        Provider(create: (_) => KitchenRepository()),
        Provider(create: (_) => PaymentRepository()),
        Provider(create: (_) => CashCutRepository()),
        ChangeNotifierProvider(
          create: (context) => PinLoginViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TablesViewModel(
            tableRepository: context.read<TableRepository>(),
            orderRepository: context.read<OrderRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderViewModel(
            productRepository: context.read<ProductRepository>(),
            orderRepository: context.read<OrderRepository>(),
            tableRepository: context.read<TableRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => KitchenViewModel(
            kitchenRepository: context.read<KitchenRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PaymentViewModel(
            paymentRepository: context.read<PaymentRepository>(),
            cashCutRepository: context.read<CashCutRepository>(),
            orderRepository: context.read<OrderRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CashCutViewModel(
            cashCutRepository: context.read<CashCutRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SOFIA Check',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.initialRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) {
          ErrorWidget.builder = (details) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 56),
                        const SizedBox(height: 12),
                        const Text(
                          'Ocurrió un error al mostrar la pantalla.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details.exceptionAsString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          };
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
