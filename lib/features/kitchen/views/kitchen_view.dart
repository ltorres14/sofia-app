import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../data/models/activity/recent_activity_item.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/kitchen/kitchen_ticket_selection.dart';
import '../../../data/models/messages/order_selection_message.dart';
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
  late final KitchenViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<KitchenViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.startRealtime();
      await _viewModel.load();
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route?.isCurrent == false) {
        return;
      }

      await _viewModel.load(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    unawaited(_viewModel.stopRealtime());
    super.dispose();
  }

  Future<void> _openSelectionHistory({
    required BuildContext context,
    required KitchenTicket ticket,
    required KitchenTicketSelection selection,
  }) async {
    final viewModel = context.read<KitchenViewModel>();
    final title =
        '${ticket.tableName} · Orden #${ticket.orderId} · Selección #${selection.sequenceNumber}';

    viewModel.setActiveSelectionHistory(selection.orderSelectionId);
    unawaited(
      viewModel.loadSelectionMessages(
        selection.orderSelectionId,
        markAsRead: true,
      ),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SelectionHistorySheet(
        orderSelectionId: selection.orderSelectionId,
        title: title,
      ),
    );

    viewModel.setActiveSelectionHistory(null);
  }

  Future<void> _openSelectionHistoryFromMessage(
    BuildContext context,
    OrderSelectionMessage message,
  ) async {
    final viewModel = context.read<KitchenViewModel>();
    final ticket = viewModel.tickets
        .where((item) => item.orderId == message.orderId)
        .cast<KitchenTicket?>()
        .firstWhere((item) => item != null, orElse: () => null);

    final selection = ticket?.selections
        .where((item) => item.orderSelectionId == message.orderSelectionId)
        .cast<KitchenTicketSelection?>()
        .firstWhere((item) => item != null, orElse: () => null);

    if (ticket != null && selection != null) {
      await _openSelectionHistory(
        context: context,
        ticket: ticket,
        selection: selection,
      );
      return;
    }

    viewModel.setActiveSelectionHistory(message.orderSelectionId);
    unawaited(
      viewModel.loadSelectionMessages(
        message.orderSelectionId,
        markAsRead: true,
      ),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SelectionHistorySheet(
        orderSelectionId: message.orderSelectionId,
        title:
            '${message.tableLabel} · Orden #${message.orderId} · ${message.selectionLabel}',
      ),
    );

    viewModel.setActiveSelectionHistory(null);
  }

  Future<void> _openPendingUpdates(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PendingUpdatesSheet(
        onOpenMessage: (message) async {
          Navigator.of(sheetContext).pop();
          await _openSelectionHistoryFromMessage(context, message);
        },
      ),
    );
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

                    final topBannerSection = Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.spacingMd,
                        responsive.spacingMd,
                        responsive.spacingMd,
                        viewModel.hasUnreadMessages ? responsive.spacingSm : 0,
                      ),
                      child: viewModel.hasUnreadMessages
                          ? _PendingUpdatesBanner(
                              count: viewModel.unreadCount,
                              onTap: () => _openPendingUpdates(context),
                            )
                          : const SizedBox.shrink(),
                    );

                    final bottomRecentSection = Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.spacingMd,
                        responsive.spacingSm,
                        responsive.spacingMd,
                        responsive.spacingMd,
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
                          if (viewModel.hasUnreadMessages) topBannerSection,
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                responsive.spacingMd,
                                responsive.spacingMd,
                                responsive.spacingMd,
                                responsive.spacingSm,
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
                                  unreadCountForSelection: (selection) =>
                                      viewModel.unreadCountForSelection(
                                        selection.orderSelectionId,
                                      ),
                                  latestUnreadMessageForSelection:
                                      (selection) => viewModel
                                          .latestUnreadMessageForSelection(
                                            selection.orderSelectionId,
                                          ),
                                  onViewSelectionMessages: (selection) =>
                                      _openSelectionHistory(
                                        context: context,
                                        ticket: ticket,
                                        selection: selection,
                                      ),
                                );
                              },
                            ),
                          ),
                          bottomRecentSection,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        if (viewModel.hasUnreadMessages) topBannerSection,
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              responsive.spacingMd,
                              responsive.spacingMd,
                              responsive.spacingMd,
                              responsive.spacingSm,
                            ),
                            itemCount: viewModel.tickets.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth >= 1400
                                      ? 3
                                      : 2,
                                  crossAxisSpacing: responsive.spacingMd,
                                  mainAxisSpacing: responsive.spacingMd,
                                  mainAxisExtent: 560,
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
                                unreadCountForSelection: (selection) =>
                                    viewModel.unreadCountForSelection(
                                      selection.orderSelectionId,
                                    ),
                                latestUnreadMessageForSelection: (selection) =>
                                    viewModel.latestUnreadMessageForSelection(
                                      selection.orderSelectionId,
                                    ),
                                onViewSelectionMessages: (selection) =>
                                    _openSelectionHistory(
                                      context: context,
                                      ticket: ticket,
                                      selection: selection,
                                    ),
                              );
                            },
                          ),
                        ),
                        bottomRecentSection,
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _PendingUpdatesBanner extends StatelessWidget {
  const _PendingUpdatesBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count actualización${count == 1 ? '' : 'es'} pendiente${count == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
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
          'Historial reciente',
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
          height: responsive.recentActivityBodyHeight,
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
      padding: EdgeInsets.only(right: responsive.spacingXs),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(width: responsive.spacingMd),
      itemBuilder: (context, index) {
        return RecentActivityCard(item: items[index], compact: true);
      },
    );
  }
}

class _PendingUpdatesSheet extends StatelessWidget {
  const _PendingUpdatesSheet({required this.onOpenMessage});

  final Future<void> Function(OrderSelectionMessage message) onOpenMessage;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Consumer<KitchenViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.spacingMd,
                responsive.spacingMd,
                responsive.spacingMd,
                responsive.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacingMd),
                  Text(
                    'Actualizaciones pendientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: responsive.spacingSm),
                  Expanded(
                    child: ListView.separated(
                      itemCount: viewModel.unreadMessages.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: responsive.spacingSm),
                      itemBuilder: (context, index) {
                        final message = viewModel.unreadMessages[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onOpenMessage(message),
                            borderRadius: BorderRadius.circular(18),
                            child: Ink(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.softBackground,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${message.tableLabel} · ${message.selectionLabel}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        DateTimeFormatter.shortTime(
                                          message.createdAt,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message.previewTitle,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  if (message.previousMessageText != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Antes: ${message.previousMessageText}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                  if (message.newMessageText != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ahora: ${message.newMessageText}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectionHistorySheet extends StatelessWidget {
  const _SelectionHistorySheet({
    required this.orderSelectionId,
    required this.title,
  });

  final int orderSelectionId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Consumer<KitchenViewModel>(
      builder: (context, viewModel, child) {
        final messages = viewModel.selectionMessagesFor(orderSelectionId);
        final isLoading = viewModel.isSelectionMessagesLoading(
          orderSelectionId,
        );
        final errorMessage = viewModel.selectionMessagesError(orderSelectionId);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.spacingMd,
                responsive.spacingMd,
                responsive.spacingMd,
                responsive.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacingMd),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: responsive.spacingSm),
                  Expanded(
                    child: isLoading && messages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : errorMessage != null && messages.isEmpty
                        ? Center(
                            child: Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: messages.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: responsive.spacingSm),
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return _SelectionHistoryMessageCard(
                                message: message,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectionHistoryMessageCard extends StatelessWidget {
  const _SelectionHistoryMessageCard({required this.message});

  final OrderSelectionMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: message.isReadByCurrentUser
            ? AppColors.softBackground
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: message.isReadByCurrentUser
              ? AppColors.border
              : AppColors.warning.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message.senderName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                DateTimeFormatter.shortTime(message.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.previewTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (message.previousMessageText != null) ...[
            const SizedBox(height: 8),
            Text(
              'Antes: ${message.previousMessageText}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (message.newMessageText != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ahora: ${message.newMessageText}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (!message.isCommentUpdated) ...[
            const SizedBox(height: 8),
            Text(
              message.messageText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
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
  const _RecentActivityState({required this.icon, required this.message});

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
