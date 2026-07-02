import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/activity/recent_activity_item.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/recent_activity_card.dart';
import '../viewmodels/kitchen_view_model.dart';
import '../widgets/kitchen_ticket_card.dart';

class KitchenView extends StatefulWidget {
  const KitchenView({super.key});

  @override
  State<KitchenView> createState() => _KitchenViewState();
}

class _KitchenViewState extends State<KitchenView> {
  Timer? _pollingTimer;
  String? _lastActionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KitchenViewModel>().load();
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route?.isCurrent == false) {
        return;
      }

      await context.read<KitchenViewModel>().load(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KitchenViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.actionErrorMessage == null) {
          _lastActionError = null;
        }

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
          child: viewModel.errorMessage != null
              ? ErrorState(
                  message: viewModel.errorMessage!,
                  onRetry: viewModel.load,
                )
              : viewModel.tickets.isEmpty
              ? const EmptyState(
                  message: 'No hay comandas pendientes en este momento.',
                  icon: Icons.check_circle_outline_rounded,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final responsive = AppResponsive.of(
                      context,
                      layoutSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    );
                    final recentSection = Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.spacingMd,
                        responsive.spacingMd,
                        responsive.spacingMd,
                        responsive.spacingSm,
                      ),
                      child: _RecentKitchenActivitySection(
                        items: viewModel.recentActivities,
                        isLoading: viewModel.isRecentActivityLoading,
                        errorMessage: viewModel.recentActivityErrorMessage,
                      ),
                    );

                    if (responsive.isPortrait || constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          recentSection,
                          Expanded(
                            child: viewModel.tickets.isEmpty
                                ? const EmptyState(
                                    message:
                                        'No hay comandas pendientes en este momento.',
                                    icon: Icons.check_circle_outline_rounded,
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.fromLTRB(
                                      responsive.spacingMd,
                                      responsive.spacingSm,
                                      responsive.spacingMd,
                                      responsive.spacingXl + 60,
                                    ),
                                    itemCount: viewModel.tickets.length,
                                    separatorBuilder: (_, _) =>
                                        SizedBox(height: responsive.spacingMd),
                                    itemBuilder: (context, index) {
                                      final ticket = viewModel.tickets[index];
                                      return KitchenTicketCard(
                                        ticket: ticket,
                                        onAdvanceStatus: () =>
                                            viewModel.advanceStatus(ticket),
                                        isLegacyActionLoading: viewModel
                                            .isLegacyActionLoading(ticket.id),
                                        onAdvanceSelectionStatus:
                                            (selection) => viewModel
                                                .advanceSelectionStatus(
                                                  ticket,
                                                  selection,
                                                ),
                                        isSelectionLoading: (selection) =>
                                            viewModel.isSelectionActionLoading(
                                              ticket.id,
                                              selection.orderSelectionId,
                                            ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        recentSection,
                        Expanded(
                          child: viewModel.tickets.isEmpty
                              ? const EmptyState(
                                  message:
                                      'No hay comandas pendientes en este momento.',
                                  icon: Icons.check_circle_outline_rounded,
                                )
                              : GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    responsive.spacingMd,
                                    responsive.spacingSm,
                                    responsive.spacingMd,
                                    responsive.spacingXl + 60,
                                  ),
                                  itemCount: viewModel.tickets.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            constraints.maxWidth >= 1400 ? 3 : 2,
                                        crossAxisSpacing: responsive.spacingMd,
                                        mainAxisSpacing: responsive.spacingMd,
                                        mainAxisExtent: 520,
                                      ),
                                  itemBuilder: (context, index) {
                                    final ticket = viewModel.tickets[index];
                                    return KitchenTicketCard(
                                      ticket: ticket,
                                      onAdvanceStatus: () =>
                                          viewModel.advanceStatus(ticket),
                                      isLegacyActionLoading: viewModel
                                          .isLegacyActionLoading(ticket.id),
                                      onAdvanceSelectionStatus: (selection) =>
                                          viewModel.advanceSelectionStatus(
                                            ticket,
                                            selection,
                                          ),
                                      isSelectionLoading: (selection) =>
                                          viewModel.isSelectionActionLoading(
                                            ticket.id,
                                            selection.orderSelectionId,
                                          ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _RecentKitchenActivitySection extends StatelessWidget {
  const _RecentKitchenActivitySection({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<RecentActivityItem> items;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos movimientos recientes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: responsive.spacingSm),
        if (errorMessage != null && items.isNotEmpty) ...[
          _RecentActivityHint(message: errorMessage!),
          SizedBox(height: responsive.spacingSm),
        ],
        SizedBox(
          height: 124,
          child: _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final responsive = AppResponsive.of(context);

    if (isLoading && items.isEmpty) {
      return const _RecentActivityState(
        icon: Icons.sync_rounded,
        message: 'Cargando movimientos recientes...',
      );
    }

    if (items.isEmpty && errorMessage != null) {
      return _RecentActivityState(
        icon: Icons.wifi_off_rounded,
        message: errorMessage!,
      );
    }

    if (items.isEmpty) {
      return const _RecentActivityState(
        icon: Icons.history_rounded,
        message: 'Sin movimientos recientes de cocina.',
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(width: responsive.spacingSm),
      itemBuilder: (context, index) {
        return RecentActivityCard(
          item: items[index],
          compact: true,
        );
      },
    );
  }
}

class _RecentActivityHint extends StatelessWidget {
  const _RecentActivityHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.16)),
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecentActivityState extends StatelessWidget {
  const _RecentActivityState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
