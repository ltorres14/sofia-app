import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/kitchen/kitchen_ticket_item.dart';
import '../../../data/models/kitchen/kitchen_ticket_selection.dart';

class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    super.key,
    required this.ticket,
    required this.onAdvanceStatus,
    required this.isLegacyActionLoading,
    required this.onAdvanceSelectionStatus,
    required this.isSelectionLoading,
  });

  final KitchenTicket ticket;
  final VoidCallback onAdvanceStatus;
  final bool isLegacyActionLoading;
  final Future<void> Function(KitchenTicketSelection selection)
  onAdvanceSelectionStatus;
  final bool Function(KitchenTicketSelection selection) isSelectionLoading;

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
              _ActionButton(
                label: ticket.status == 1
                    ? 'Marcar preparando'
                    : 'Marcar listo',
                icon: Icons.local_fire_department_rounded,
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

    return [
      for (final selection in ticket.selections) ...[
        _SelectionCard(
          selection: selection,
          responsive: responsive,
          theme: theme,
          selectionLoading: isSelectionLoading(selection),
          onAdvanceSelectionStatus: onAdvanceSelectionStatus,
          itemListBuilder: (items) =>
              _buildSelectionItemList(context, items, responsive),
        ),
        SizedBox(height: responsive.spacingSm),
      ],
      if (ticket.legacyItems.isNotEmpty)
        ..._buildSelectionItemList(context, ticket.legacyItems, responsive),
    ];
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
      for (final item in items) ...[
        _buildItemTile(context, item),
        SizedBox(height: responsive.spacingSm),
      ],
    ];
  }

  Widget _buildItemTile(BuildContext context, KitchenTicketItem item) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);
    final notes = item.notes?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.quantity} x ${item.productName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: responsive.orderBodyFontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (notes.isNotEmpty) ...[
            SizedBox(height: responsive.spacingXs),
            Text(
              notes,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: responsive.captionFontSize,
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

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.selection,
    required this.responsive,
    required this.theme,
    required this.selectionLoading,
    required this.onAdvanceSelectionStatus,
    required this.itemListBuilder,
  });

  final KitchenTicketSelection selection;
  final AppResponsive responsive;
  final ThemeData theme;
  final bool selectionLoading;
  final Future<void> Function(KitchenTicketSelection selection)
  onAdvanceSelectionStatus;
  final List<Widget> Function(List<KitchenTicketItem> items) itemListBuilder;

  @override
  Widget build(BuildContext context) {
    final selectionStatus = _statusPresentation(selection.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.softBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
          if (selection.hasComment) ...[
            SizedBox(height: responsive.spacingXs),
            Text(
              selection.displayComment,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: responsive.captionFontSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: responsive.spacingSm),
          ...itemListBuilder(selection.items),
          if (selection.status < 3) ...[
            SizedBox(height: responsive.spacingXs),
            _ActionButton(
              label: selection.status == 1
                  ? 'Marcar preparando'
                  : 'Marcar listo',
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
      ),
    );
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
