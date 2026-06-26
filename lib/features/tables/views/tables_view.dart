import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/routing/route_access.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/tables_view_model.dart';
import '../widgets/table_card.dart';
import '../../orders/viewmodels/order_view_model.dart';

class TablesView extends StatefulWidget {
  const TablesView({super.key});

  @override
  State<TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<TablesView> {
  String? _lastActionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TablesViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return Consumer<TablesViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.actionErrorMessage != null &&
            viewModel.actionErrorMessage != _lastActionError) {
          final actionError = viewModel.actionErrorMessage!;
          _lastActionError = actionError;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(actionError)));

            viewModel.clearActionError();
          });
        }

        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final responsiveHelper = ResponsiveHelper(context);
              final screenHeight = responsiveHelper.height;
              final screenWidth = responsiveHelper.width;

              final responsive = AppResponsive.of(
                context,
                layoutSize: Size(constraints.maxWidth, constraints.maxHeight),
              );

              final isMobilePortrait =
                  responsive.isPortrait && !responsive.isTablet;

              final horizontalPadding = isMobilePortrait
                  ? responsiveHelper.percentWidth(0.04)
                  : responsive.horizontalPadding;

              final topPadding = isMobilePortrait
                  ? responsiveHelper.percentHeight(0.012)
                  : responsive.verticalPadding;

              final bottomPadding = isMobilePortrait
                  ? responsiveHelper.percentHeight(0.015)
                  : responsive.spacingSm;

              final cardHeight = isMobilePortrait
                  ? screenHeight * 0.115
                  : responsive.tableCardHeight;

              final gridColumns = isMobilePortrait
                  ? 2
                  : responsive.tableGridColumns;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TablesHeader(
                      isMobilePortrait: isMobilePortrait,
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      onRefresh: viewModel.load,
                      onCreateOrder: viewModel.tables.isEmpty
                          ? null
                          : () async {
                              final freeTable = viewModel.tables.firstWhere(
                                (t) => t.isFree,
                              );

                              try {
                                await viewModel.ensureOrderForTable(freeTable);

                                final role = authRepository.currentUser?.role;

                                if (context.mounted &&
                                    RouteAccess.canAccess(
                                      role: role,
                                      routeName: RouteNames.order,
                                    )) {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.order,
                                    arguments: freeTable,
                                  );
                                } else if (context.mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    RouteAccess.defaultRouteForRole(role),
                                  );
                                }
                              } catch (_) {
                                // El ViewModel ya expone el error a la UI.
                              }
                            },
                    ),
                    SizedBox(height: screenHeight * 0.018),
                    if (viewModel.errorMessage != null)
                      Expanded(
                        child: ErrorState(
                          message: viewModel.errorMessage!,
                          onRetry: viewModel.load,
                        ),
                      )
                    else
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.only(
                            bottom: screenHeight * 0.025,
                          ),
                          itemCount: viewModel.tables.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridColumns,
                                crossAxisSpacing: screenWidth * 0.03,
                                mainAxisSpacing: screenHeight * 0.018,
                                mainAxisExtent: cardHeight.clamp(170.0, 190.0),
                              ),
                          itemBuilder: (context, index) {
                            final table = viewModel.tables[index];
                            final draftSelectionCount =
                                OrderViewModel.draftSelectionCountForTable(
                                  table.id,
                                );
                            return TableCard(
                              table: table,
                              responsive: responsive,
                              draftSelectionCount: draftSelectionCount,
                              onTap: () async {
                                final role = authRepository.currentUser?.role;
                                final canOpenPayments = RouteAccess.canAccess(
                                  role: role,
                                  routeName: RouteNames.payments,
                                );

                                if (table.waitingPayment &&
                                    canOpenPayments &&
                                    context.mounted) {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.payments,
                                    arguments: table.id,
                                  );
                                  return;
                                }

                                try {
                                  await viewModel.ensureOrderForTable(table);

                                  if (context.mounted &&
                                      RouteAccess.canAccess(
                                        role: role,
                                        routeName: RouteNames.order,
                                      )) {
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.order,
                                      arguments: table,
                                    );
                                  } else if (context.mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      RouteAccess.defaultRouteForRole(role),
                                    );
                                  }
                                } catch (_) {
                                  // El ViewModel ya expone el error a la UI.
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TablesHeader extends StatelessWidget {
  const _TablesHeader({
    required this.isMobilePortrait,
    required this.screenHeight,
    required this.screenWidth,
    required this.onRefresh,
    required this.onCreateOrder,
  });

  final bool isMobilePortrait;
  final double screenHeight;
  final double screenWidth;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateOrder;

  @override
  Widget build(BuildContext context) {
    final buttonSize = isMobilePortrait ? screenWidth * 0.105 : 44.0;
    final iconSize = isMobilePortrait ? 21.0 : 22.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Seleccione',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: isMobilePortrait ? 13 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        _HeaderActionButton(
          icon: Icons.refresh_rounded,
          onPressed: onRefresh,
          filled: false,
          size: buttonSize.clamp(40.0, 46.0),
          iconSize: iconSize,
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onPressed,
    required this.filled,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x127C4A12),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: filled ? Colors.white : AppColors.primary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
