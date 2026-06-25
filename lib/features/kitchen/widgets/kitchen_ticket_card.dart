import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/kitchen/kitchen_ticket_item.dart';

class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    super.key,
    required this.ticket,
    required this.onAdvanceStatus,
  });

  final KitchenTicket ticket;
  final VoidCallback onAdvanceStatus;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);
    final statusText = switch (ticket.status) {
      1 => 'Pendiente',
      2 => 'Preparando',
      3 => 'Listo',
      _ => 'Cancelado',
    };
    final statusColor = switch (ticket.status) {
      1 => AppColors.warning,
      2 => AppColors.primary,
      3 => AppColors.success,
      _ => AppColors.danger,
    };

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
                    label: statusText,
                    color: statusColor,
                    responsive: responsive,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacingXs),
            Text(
              'Orden #${ticket.orderId} · ${DateTimeFormatter.shortTime(ticket.createdAt)}',
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
            SizedBox(height: responsive.spacingMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ticket.status >= 3 ? null : onAdvanceStatus,
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
                icon: const Icon(Icons.local_fire_department_rounded),
                label: Text(
                  ticket.status == 1 ? 'Marcar preparando' : 'Marcar listo',
                ),
              ),
            ),
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
        Container(
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
              Text(
                selection.label.isNotEmpty
                    ? selection.label
                    : 'Selección ${selection.sequenceNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: responsive.orderBodyFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              if ((selection.comment ?? '').trim().isNotEmpty) ...[
                SizedBox(height: responsive.spacingXs),
                Text(
                  selection.comment?.trim() ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: responsive.spacingSm),
              ..._buildSelectionItemList(context, selection.items, responsive),
            ],
          ),
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
