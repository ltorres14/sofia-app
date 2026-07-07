import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/business_config.dart';
import '../../core/responsive/app_responsive.dart';
import '../../core/routing/route_access.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/more_bottom_sheet.dart';
import '../widgets/pos_bottom_nav.dart';
import 'pos_header.dart';

class PosShell extends StatelessWidget {
  const PosShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.currentRoute,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String currentRoute;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final authRepository = context.read<AuthRepository>();
    final role = authRepository.currentUser?.role;
    final bottomNavItems = _buildBottomNavItems(role);
    final showBottomNav = responsive.isPortrait && bottomNavItems.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: showBottomNav
          ? PosBottomNav(
              items: bottomNavItems,
              currentRoute: currentRoute,
              onTap: (item) => _handleBottomNavTap(
                context,
                item: item,
                authRepository: authRepository,
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 1400
                ? 1400.0
                : constraints.maxWidth.toDouble();

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: responsive.contentPadding,
                  child: Column(
                    children: [
                      PosHeader(
                        title: BusinessConfig.current.businessName,
                        subtitle: subtitle,
                        leading: leading,
                        trailing: trailing,
                      ),
                      SizedBox(height: responsive.sectionGap),
                      Expanded(child: child),
                      if (!responsive.isPortrait ||
                          responsive.screenWidth >= 600)
                        Padding(
                          padding: EdgeInsets.only(top: responsive.spacingSm),
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontSize: responsive.captionFontSize,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<PosBottomNavItem> _buildBottomNavItems(String? role) {
    final items = <PosBottomNavItem>[];

    if (RouteAccess.canAccess(role: role, routeName: RouteNames.tables)) {
      items.add(
        const PosBottomNavItem(
          label: 'Mesas',
          icon: Icons.table_restaurant_rounded,
          routeName: RouteNames.tables,
        ),
      );
    }

    if (RouteAccess.canAccess(role: role, routeName: RouteNames.kitchen)) {
      items.add(
        const PosBottomNavItem(
          label: 'Cocina',
          icon: Icons.soup_kitchen_rounded,
          routeName: RouteNames.kitchen,
        ),
      );
    }

    items.add(
      const PosBottomNavItem(
        label: 'Más',
        icon: Icons.more_horiz_rounded,
        isMore: true,
      ),
    );

    return items;
  }

  Future<void> _handleBottomNavTap(
    BuildContext context, {
    required PosBottomNavItem item,
    required AuthRepository authRepository,
  }) async {
    if (item.isMore) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final user = authRepository.currentUser;
          return MoreBottomSheet(
            userName: user?.name ?? 'Usuario',
            roleName: user?.role ?? 'Sin rol',
            onPayments:
                RouteAccess.canAccess(
                  role: user?.role,
                  routeName: RouteNames.payments,
                )
                ? () => _navigateFromMoreSheet(
                    context,
                    sheetContext,
                    RouteNames.payments,
                  )
                : null,
            onCashCut:
                RouteAccess.canAccess(
                  role: user?.role,
                  routeName: RouteNames.cashCut,
                )
                ? () => _navigateFromMoreSheet(
                    context,
                    sheetContext,
                    RouteNames.cashCut,
                  )
                : null,
            onTodaySales:
                RouteAccess.canAccess(
                  role: user?.role,
                  routeName: RouteNames.todaySales,
                )
                ? () => _navigateFromMoreSheet(
                    context,
                    sheetContext,
                    RouteNames.todaySales,
                  )
                : null,
            onProfile: () => Navigator.of(sheetContext).pop(),
            onSync: () => Navigator.of(sheetContext).pop(),
            onSettings: () => Navigator.of(sheetContext).pop(),
            onSupport: () => Navigator.of(sheetContext).pop(),
            onLogout: () async {
              Navigator.of(sheetContext).pop();
              await authRepository.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
              }
            },
          );
        },
      );
      return;
    }

    final routeName = item.routeName;
    if (routeName == null || routeName == currentRoute) {
      return;
    }

    final role = authRepository.currentUser?.role;
    if (!RouteAccess.canAccess(role: role, routeName: routeName)) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(routeName);
  }

  void _navigateFromMoreSheet(
    BuildContext context,
    BuildContext sheetContext,
    String routeName,
  ) {
    Navigator.of(sheetContext).pop();
    if (routeName == currentRoute) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(routeName);
  }
}
