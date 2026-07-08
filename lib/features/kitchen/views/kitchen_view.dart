import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/kitchen/kitchen_ticket_selection.dart';
import '../../../data/models/messages/order_selection_message.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/recent_activity_bottom_sheet.dart';
import '../../../shared/widgets/sofia_bottom_sheet_header.dart';
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
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PendingUpdatesSheet(
        onOpenMessage: (message) async {
          Navigator.of(sheetContext).pop();
          await _openSelectionHistoryFromMessage(context, message);
        },
      ),
    );
  }

  Future<void> _openRecentHistory(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer<KitchenViewModel>(
        builder: (context, viewModel, child) => RecentActivityBottomSheet(
          items: viewModel.recentActivities,
          isLoading: viewModel.isRecentActivityLoading,
          errorMessage: viewModel.recentActivityErrorMessage,
          emptyMessage: 'Sin movimientos recientes de cocina.',
        ),
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final responsive = AppResponsive.of(
                      context,
                      layoutSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    );

                    final topControlsSection = Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.spacingMd,
                        responsive.spacingMd,
                        responsive.spacingMd,
                        responsive.spacingSm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _PendingUpdatesIconButton(
                            hasUnreadMessages: viewModel.hasUnreadMessages,
                            onTap: viewModel.hasUnreadMessages
                                ? () => _openPendingUpdates(context)
                                : null,
                          ),
                          SizedBox(width: responsive.spacingSm),
                          RecentActivityHistoryButton(
                            isLoading:
                                viewModel.isRecentActivityLoading &&
                                viewModel.recentActivities.isEmpty,
                            onTap: () => _openRecentHistory(context),
                          ),
                        ],
                      ),
                    );

                    if (responsive.isPortrait || constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          topControlsSection,
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
                                      0,
                                      responsive.spacingMd,
                                      responsive.spacingMd,
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
                        ],
                      );
                    }

                    return Column(
                      children: [
                        topControlsSection,
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
                                    0,
                                    responsive.spacingMd,
                                    responsive.spacingMd,
                                  ),
                                  itemCount: viewModel.tickets.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            constraints.maxWidth >= 1400
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
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _PendingUpdatesIconButton extends StatelessWidget {
  const _PendingUpdatesIconButton({
    required this.hasUnreadMessages,
    required this.onTap,
  });

  final bool hasUnreadMessages;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Tooltip(
      message: hasUnreadMessages
          ? 'Ver actualizaciones nuevas'
          : 'No hay actualizaciones nuevas',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: responsive.spacingXl * 2,
            height: responsive.spacingXl * 2,
            decoration: BoxDecoration(
              color: hasUnreadMessages
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.softBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: hasUnreadMessages
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : AppColors.border,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    hasUnreadMessages
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 20,
                    color: hasUnreadMessages
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                if (hasUnreadMessages)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    /*
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count actualización${count == 1 ? '' : 'es'} nueva${count == 1 ? '' : 's'}',
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
    */
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
        final displayedMessages =
            List<OrderSelectionMessage>.from(viewModel.unreadMessages)..sort((
              left,
              right,
            ) {
              final dateComparison = right.createdAt.compareTo(left.createdAt);
              if (dateComparison != 0) {
                return dateComparison;
              }

              return right.id.compareTo(left.id);
            });

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
                  const SofiaBottomSheetHeader(
                    title: 'Actualizaciones nuevas',
                    showHandle: true,
                  ),
                  SizedBox(height: responsive.spacingSm),
                  Expanded(
                    child: ListView.separated(
                      itemCount: displayedMessages.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: responsive.spacingSm),
                      itemBuilder: (context, index) {
                        final message = displayedMessages[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onOpenMessage(message),
                            borderRadius: BorderRadius.circular(18),
                            child: Ink(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.04,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
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
                                    message.isCommentUpdated
                                        ? 'Nuevo comentario'
                                        : 'Nuevo mensaje',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.newMessageText ??
                                        message.messageText,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
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
                  SofiaBottomSheetHeader(
                    title: title,
                    showHandle: true,
                    titleMaxLines: 2,
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
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: message.isReadByCurrentUser
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.16),
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
