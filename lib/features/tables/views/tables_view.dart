import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/business_config.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/layouts/responsive_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/safe_app_image.dart';
import '../viewmodels/tables_view_model.dart';
import '../widgets/table_card.dart';
import '../widgets/table_status_legend.dart';

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
          child: ResponsiveScaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final responsive = AppResponsive.of(
                  context,
                  layoutSize: Size(constraints.maxWidth, constraints.maxHeight),
                );
                final isMobilePortrait =
                    responsive.isPortrait && !responsive.isTablet;
                final horizontalPadding = responsive.isPortrait
                    ? 16.0
                    : responsive.horizontalPadding;
                final verticalPadding = responsive.isPortrait
                    ? 12.0
                    : responsive.verticalPadding;
                final cardHeight = isMobilePortrait
                    ? 118.0
                    : responsive.tableCardHeight;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    responsive.spacingSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TablesHeader(
                        isMobilePortrait: isMobilePortrait,
                        onRefresh: viewModel.load,
                        onCreateOrder: viewModel.tables.isEmpty
                            ? null
                            : () async {
                                final freeTable = viewModel.tables.firstWhere(
                                  (t) => t.isFree,
                                );
                                try {
                                  await viewModel.ensureOrderForTable(
                                    freeTable,
                                  );
                                  if (context.mounted) {
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.order,
                                      arguments: freeTable,
                                    );
                                  }
                                } catch (_) {
                                  // El ViewModel ya expone el error a la UI.
                                }
                              },
                      ),
                      SizedBox(
                        height: isMobilePortrait ? 24 : responsive.spacingMd,
                      ),
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
                              bottom: isMobilePortrait
                                  ? responsive.spacingXs
                                  : responsive.spacingSm,
                            ),
                            itemCount: viewModel.tables.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobilePortrait
                                      ? 2
                                      : responsive.tableGridColumns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: cardHeight,
                                ),
                            itemBuilder: (context, index) {
                              final table = viewModel.tables[index];
                              return TableCard(
                                table: table,
                                responsive: responsive,
                                onTap: () async {
                                  try {
                                    await viewModel.ensureOrderForTable(table);
                                    if (context.mounted) {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.order,
                                        arguments: table,
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
          ),
        );
      },
    );
  }
}

class _TablesHeader extends StatelessWidget {
  const _TablesHeader({
    required this.isMobilePortrait,
    required this.onRefresh,
    required this.onCreateOrder,
  });

  final bool isMobilePortrait;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateOrder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x127C4A12),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(9),
          child: SafeAppImage.asset(
            assetPath: BusinessConfig.current.logoAssetPath,
            fallbackIcon: Icons.storefront_rounded,
            fit: BoxFit.contain,
            iconSize: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                BusinessConfig.current.businessName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: isMobilePortrait ? 21 : 32,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mesas del turno',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isMobilePortrait ? 13 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderActionButton(
              icon: Icons.refresh_rounded,
              onPressed: onRefresh,
              filled: false,
            ),
            const SizedBox(width: 8),
            _HeaderActionButton(
              icon: Icons.add_rounded,
              onPressed: onCreateOrder,
              filled: true,
            ),
          ],
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
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryAmber : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: filled ? AppColors.primaryAmber : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled ? AppColors.primaryAmber : AppColors.border,
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
            color: filled ? Colors.white : AppColors.primaryAmber,
            size: 22,
          ),
        ),
      ),
    );
  }
}
