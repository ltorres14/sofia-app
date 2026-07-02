import 'package:flutter/material.dart';

import '../../core/responsive/app_responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../data/models/activity/recent_activity_item.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.item,
    this.compact = false,
  });

  final RecentActivityItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);
    final horizontalPadding = compact
        ? responsive.spacingSm
        : responsive.spacingMd;
    final verticalPadding = compact
        ? responsive.spacingSm
        : responsive.spacingMd;
    final iconSize = compact ? 18.0 : 22.0;
    final titleFontSize = compact
        ? responsive.bodyFontSize
        : responsive.orderBodyFontSize;
    final secondaryFontSize = compact
        ? responsive.captionFontSize
        : responsive.bodyFontSize;

    return Container(
      width: compact
          ? responsive.isTablet
                ? 260
                : 230
          : responsive.isTablet
          ? 320
          : 280,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                decoration: BoxDecoration(
                  color: _iconColor(item.eventType).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForEvent(item.eventType),
                  color: _iconColor(item.eventType),
                  size: iconSize,
                ),
              ),
              SizedBox(width: responsive.spacingSm),
              Expanded(
                child: Text(
                  item.description,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? responsive.spacingXs : responsive.spacingSm),
          Text(
            item.tableName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: secondaryFontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacingXs),
          Wrap(
            spacing: responsive.spacingXs,
            runSpacing: responsive.spacingXs,
            children: [
              if (item.hasStatus)
                _InfoChip(
                  label: item.statusLabel!,
                  color: _statusColor(item.statusLabel!),
                ),
              _InfoChip(
                label:
                    '${DateTimeFormatter.shortDate(item.activityAt)} ${DateTimeFormatter.shortTime(item.activityAt)}',
              ),
              if (item.hasTotal && item.total != null)
                _InfoChip(label: CurrencyFormatter.format(item.total!)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForEvent(String eventType) {
    switch (eventType.trim().toLowerCase()) {
      case 'order_opened':
        return Icons.playlist_add_circle_rounded;
      case 'order_selection_created':
      case 'order_selection_updated':
      case 'order_selection_comment_updated':
        return Icons.edit_note_rounded;
      case 'order_selection_cancelled':
        return Icons.remove_circle_outline_rounded;
      case 'order_sent_to_kitchen':
      case 'kitchen_ticket_sent':
        return Icons.restaurant_rounded;
      case 'order_bill_requested':
        return Icons.receipt_long_rounded;
      case 'order_paid':
        return Icons.payments_rounded;
      case 'kitchen_ticket_preparing':
        return Icons.local_fire_department_rounded;
      case 'kitchen_ticket_ready':
      case 'kitchen_ticket_status_updated':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _iconColor(String eventType) {
    switch (eventType.trim().toLowerCase()) {
      case 'order_selection_cancelled':
        return AppColors.danger;
      case 'order_bill_requested':
        return AppColors.warning;
      case 'order_paid':
      case 'kitchen_ticket_ready':
        return AppColors.success;
      case 'kitchen_ticket_preparing':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();

    if (normalized.contains('cancel')) {
      return AppColors.danger;
    }

    if (normalized.contains('pagad') || normalized.contains('list')) {
      return AppColors.success;
    }

    if (normalized.contains('cuenta') || normalized.contains('enviad')) {
      return AppColors.warning;
    }

    if (normalized.contains('prepar')) {
      return AppColors.primary;
    }

    return AppColors.textSecondary;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
