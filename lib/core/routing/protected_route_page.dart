import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import 'route_access.dart';
import 'route_names.dart';

class ProtectedRoutePage extends StatefulWidget {
  const ProtectedRoutePage({
    super.key,
    required this.routeName,
    required this.child,
  });

  final String routeName;
  final Widget child;

  @override
  State<ProtectedRoutePage> createState() => _ProtectedRoutePageState();
}

class _ProtectedRoutePageState extends State<ProtectedRoutePage> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final role = authRepository.currentUser?.role;
    final allowed = RouteAccess.canAccess(
      role: role,
      routeName: widget.routeName,
    );

    if (allowed) {
      return widget.child;
    }

    final fallbackRoute = RouteAccess.defaultRouteForRole(role);
    final shouldRedirect =
        fallbackRoute != widget.routeName && fallbackRoute != RouteNames.login;

    if (shouldRedirect && !_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(fallbackRoute);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'Acceso restringido',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  shouldRedirect
                      ? 'Redirigiendo a una pantalla permitida.'
                      : 'No tienes permiso para abrir esta pantalla.',
                  textAlign: TextAlign.center,
                ),
                if (!shouldRedirect) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        RouteNames.login,
                        (route) => false,
                      );
                    },
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
