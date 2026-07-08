import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/kitchen/kitchen_ticket_item.dart';
import '../../../data/models/kitchen/kitchen_ticket_selection.dart';
import '../../../data/models/messages/order_selection_message.dart';

class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    super.key,
    required this.ticket,
    required this.onAdvanceStatus,
    required this.isLegacyActionLoading,
    required this.onAdvanceSelectionStatus,
    required this.isSelectionLoading,
    required this.unreadCountForSelection,
    required this.latestUnreadMessageForSelection,
    required this.onViewSelectionMessages,
  });

  final KitchenTicket ticket;
  final VoidCallback onAdvanceStatus;
  final bool isLegacyActionLoading;
  final Future<void> Function(KitchenTicketSelection selection)
  onAdvanceSelectionStatus;
  final bool Function(KitchenTicketSelection selection) isSelectionLoading;
  final int Function(KitchenTicketSelection selection) unreadCountForSelection;
  final OrderSelectionMessage? Function(KitchenTicketSelection selection)
  latestUnreadMessageForSelection;
  final void Function(KitchenTicketSelection selection) onViewSelectionMessages;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);
    final ticketStatus = _statusPresentation(ticket.status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.productListCardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ticket.tableName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: responsive.orderTitleFontSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacingSm),
                Flexible(
                  child: _StatusChip(
                    label: ticketStatus.label,
                    color: ticketStatus.color,
                    responsive: responsive,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacingXs),
            Text(
              'Orden #${ticket.orderId} - ${DateTimeFormatter.shortTime(ticket.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: responsive.captionFontSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: responsive.spacingMd),
            if (ticket.selections.isNotEmpty)
              ..._buildSelectionItems(context, responsive)
            else
              ..._buildLegacyItems(context, responsive),
            if (ticket.selections.isEmpty) ...[
              SizedBox(height: responsive.spacingMd),
              const Divider(height: 1, color: AppColors.border),
              SizedBox(height: responsive.spacingMd),
              _ActionButton(
                label: ticket.status == 1
                    ? 'Marcar preparando'
                    : 'Marcar listo',
                icon: ticket.status == 1
                    ? Icons.local_fire_department_rounded
                    : Icons.check_circle_rounded,
                onPressed: ticket.status >= 3 || isLegacyActionLoading
                    ? null
                    : onAdvanceStatus,
                loading: isLegacyActionLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectionItems(
    BuildContext context,
    AppResponsive responsive,
  ) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    for (var index = 0; index < ticket.selections.length; index++) {
      final selection = ticket.selections[index];
      if (index > 0) {
        widgets.add(SizedBox(height: responsive.spacingMd));
        widgets.add(const Divider(height: 1, color: AppColors.border));
        widgets.add(SizedBox(height: responsive.spacingMd));
      }

      widgets.add(
        _SelectionSection(
          selection: selection,
          responsive: responsive,
          theme: theme,
          selectionLoading: isSelectionLoading(selection),
          onAdvanceSelectionStatus: onAdvanceSelectionStatus,
          itemListBuilder: (items) =>
              _buildSelectionItemList(context, items, responsive),
          unreadCount: unreadCountForSelection(selection),
          latestUnreadMessage: latestUnreadMessageForSelection(selection),
          onViewSelectionMessages: onViewSelectionMessages,
        ),
      );
    }

    if (ticket.legacyItems.isNotEmpty) {
      if (widgets.isNotEmpty) {
        widgets.add(SizedBox(height: responsive.spacingMd));
        widgets.add(const Divider(height: 1, color: AppColors.border));
        widgets.add(SizedBox(height: responsive.spacingMd));
      }
      widgets.addAll(
        _buildSelectionItemList(context, ticket.legacyItems, responsive),
      );
    }

    return widgets;
  }

  List<Widget> _buildLegacyItems(
    BuildContext context,
    AppResponsive responsive,
  ) {
    return _buildSelectionItemList(context, ticket.items, responsive);
  }

  List<Widget> _buildSelectionItemList(
    BuildContext context,
    List<KitchenTicketItem> items,
    AppResponsive responsive,
  ) {
    return [
      for (var index = 0; index < items.length; index++) ...[
        _buildItemTile(context, items[index]),
        if (index < items.length - 1) SizedBox(height: responsive.spacingSm),
      ],
    ];
  }

  Widget _buildItemTile(BuildContext context, KitchenTicketItem item) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);
    final notes = item.notes?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.quantity} × ${item.productName}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: responsive.orderBodyFontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (notes.isNotEmpty) ...[
          SizedBox(height: responsive.spacingXs / 2),
          Padding(
            padding: EdgeInsets.only(left: responsive.spacingSm),
            child: Text(
              notes,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: responsive.captionFontSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectionSection extends StatelessWidget {
  const _SelectionSection({
    required this.selection,
    required this.responsive,
    required this.theme,
    required this.selectionLoading,
    required this.onAdvanceSelectionStatus,
    required this.itemListBuilder,
    required this.unreadCount,
    required this.latestUnreadMessage,
    required this.onViewSelectionMessages,
  });

  final KitchenTicketSelection selection;
  final AppResponsive responsive;
  final ThemeData theme;
  final bool selectionLoading;
  final Future<void> Function(KitchenTicketSelection selection)
  onAdvanceSelectionStatus;
  final List<Widget> Function(List<KitchenTicketItem> items) itemListBuilder;
  final int unreadCount;
  final OrderSelectionMessage? latestUnreadMessage;
  final void Function(KitchenTicketSelection selection) onViewSelectionMessages;

  @override
  Widget build(BuildContext context) {
    final selectionStatus = _statusPresentation(selection.status);
    final hasUnreadMessage = latestUnreadMessage != null;
    final hasUnreadCommentUpdate =
        latestUnreadMessage?.isCommentUpdated ?? false;
    final unreadPreviewText = hasUnreadMessage
        ? _messagePreviewText(latestUnreadMessage!)
        : null;
    final commentText = hasUnreadMessage
        ? null
        : (selection.hasComment ? selection.displayComment : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                selection.label.isNotEmpty
                    ? selection.label
                    : 'Selección ${selection.sequenceNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: responsive.orderBodyFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: responsive.spacingSm),
            Flexible(
              child: _StatusChip(
                label: selectionStatus.label,
                color: selectionStatus.color,
                responsive: responsive,
              ),
            ),
          ],
        ),
        if (unreadCount > 0) ...[
          SizedBox(height: responsive.spacingSm),
          _UnreadBadge(
            count: unreadCount,
            hasCommentUpdate: hasUnreadCommentUpdate,
          ),
        ],
        if (hasUnreadMessage || commentText != null) ...[
          SizedBox(height: responsive.spacingSm),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(height: responsive.spacingSm),
          if (hasUnreadMessage)
            if (hasUnreadCommentUpdate)
              _CommentBlock(
                text: unreadPreviewText!,
                responsive: responsive,
                theme: theme,
              )
            else
              _UnreadMessagePreview(
                message: latestUnreadMessage!,
                responsive: responsive,
                theme: theme,
              )
          else
            _CommentBlock(
              text: commentText!,
              responsive: responsive,
              theme: theme,
            ),
        ],
        if (selection.items.isNotEmpty) ...[
          SizedBox(height: responsive.spacingSm),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(height: responsive.spacingSm),
          ...itemListBuilder(selection.items),
        ],
        SizedBox(height: responsive.spacingSm),
        const Divider(height: 1, color: AppColors.border),
        SizedBox(height: responsive.spacingSm),
        TextButton.icon(
          onPressed: () => onViewSelectionMessages(selection),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: const Text('Ver mensajes'),
        ),
        if (selection.status < 3) ...[
          SizedBox(height: responsive.spacingSm),
          _ActionButton(
            label: selection.status == 1 ? 'Marcar preparando' : 'Marcar listo',
            icon: selection.status == 1
                ? Icons.local_fire_department_rounded
                : Icons.check_circle_rounded,
            onPressed: selectionLoading
                ? null
                : () {
                    onAdvanceSelectionStatus(selection);
                  },
            loading: selectionLoading,
          ),
        ],
      ],
    );
  }

  String _messagePreviewText(OrderSelectionMessage message) {
    if (message.newMessageText != null) {
      return message.newMessageText!;
    }

    if (message.messageText.isNotEmpty) {
      return message.messageText;
    }

    return message.previewTitle;
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.hasCommentUpdate});

  final int count;
  final bool hasCommentUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_chat_unread_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            hasCommentUpdate
                ? 'Nuevo comentario'
                : '$count mensaje${count == 1 ? '' : 's'} nuevo${count == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBlock extends StatelessWidget {
  const _CommentBlock({
    required this.text,
    required this.responsive,
    required this.theme,
  });

  final String text;
  final AppResponsive responsive;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        SizedBox(width: responsive.spacingXs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: responsive.captionFontSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnreadMessagePreview extends StatelessWidget {
  const _UnreadMessagePreview({
    required this.message,
    required this.responsive,
    required this.theme,
  });

  final OrderSelectionMessage message;
  final AppResponsive responsive;
  final ThemeData theme;

  String get _headline =>
      message.isCommentUpdated ? 'Nuevo comentario' : 'Nuevo mensaje';

  String get _messageBody {
    if (message.newMessageText != null) {
      return message.newMessageText!;
    }

    if (message.messageText.isNotEmpty) {
      return message.messageText;
    }

    return message.previewTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            SizedBox(width: responsive.spacingXs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: responsive.spacingXs / 2),
                  Text(
                    _relativeTime(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: responsive.captionFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacingSm),
        Text(
          _messageBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _relativeTime(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value.toLocal());

    if (difference.inSeconds < 10) {
      return 'Ahora';
    }
    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    }
    if (difference.inMinutes == 1) {
      return 'Hace 1 min';
    }
    if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours == 1) {
      return 'Hace 1 h';
    }

    return 'Hace ${difference.inHours} h';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: Size(
            double.infinity,
            responsive.orderActionButtonHeight.clamp(48.0, 56.0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.white,
                  ),
                ),
              )
            else
              Icon(icon),
            SizedBox(width: responsive.spacingSm),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.responsive,
  });

  final String label;
  final Color color;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacingSm,
          vertical: responsive.spacingXs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

_KitchenStatusPresentation _statusPresentation(int status) {
  return switch (status) {
    1 => _KitchenStatusPresentation('Pendiente', AppColors.warning),
    2 => _KitchenStatusPresentation('Preparando', AppColors.primary),
    3 => _KitchenStatusPresentation('Listo', AppColors.success),
    _ => _KitchenStatusPresentation('Cancelado', AppColors.danger),
  };
}

class _KitchenStatusPresentation {
  const _KitchenStatusPresentation(this.label, this.color);

  final String label;
  final Color color;
}
