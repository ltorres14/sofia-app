import 'package:flutter/material.dart';

import '../../core/responsive/app_responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
    final cardWidth = compact
        ? (responsive.isTablet ? 252.0 : 224.0)
        : responsive.isTablet
        ? 320.0
        : responsive.screenWidth.clamp(280.0, 304.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTightLayout = compact || constraints.maxHeight <= 166;
        final horizontalPadding = useTightLayout
            ? responsive.spacingSm.clamp(8.0, 10.0)
            : responsive.spacingMd;
        final verticalPadding = useTightLayout
            ? responsive.spacingXs.clamp(6.0, 8.0)
            : responsive.spacingMd;
        final iconContainerSize = useTightLayout ? 30.0 : 40.0;
        final iconSize = useTightLayout ? 16.0 : 22.0;
        final titleFontSize = useTightLayout
            ? responsive.orderBodyFontSize.clamp(12.0, 13.0)
            : responsive.orderBodyFontSize;
        final secondaryFontSize = useTightLayout
            ? responsive.captionFontSize.clamp(11.0, 12.0)
            : responsive.bodyFontSize;
        final titleGap = useTightLayout
            ? responsive.spacingXs.clamp(4.0, 6.0)
            : responsive.spacingSm;
        final contentGap = useTightLayout
            ? responsive.spacingXs.clamp(4.0, 6.0)
            : responsive.spacingSm;
        final chipGap = useTightLayout
            ? responsive.spacingXs.clamp(4.0, 6.0)
            : responsive.spacingXs;
        final maxChipWidth =
            (cardWidth - (horizontalPadding * 2)) *
            (useTightLayout ? 0.58 : 0.74);

        return Container(
          width: cardWidth,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(useTightLayout ? 20 : 24),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: _iconColor(item.eventType).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        useTightLayout ? 10 : 12,
                      ),
                    ),
                    child: Icon(
                      _iconForEvent(item.eventType),
                      color: _iconColor(item.eventType),
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: titleGap),
                  Expanded(
                    child: Text(
                      item.description,
                      maxLines: useTightLayout ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: useTightLayout ? 1.1 : 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: contentGap),
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
              SizedBox(height: contentGap),
              Wrap(
                spacing: chipGap,
                runSpacing: chipGap,
                children: [
                  if (item.hasStatus)
                    _InfoChip(
                      label: item.statusLabel!,
                      color: _statusColor(item.statusLabel!),
                      maxWidth: maxChipWidth,
                      compact: useTightLayout,
                    ),
                  _InfoChip(
                    label:
                        '${DateTimeFormatter.shortDate(item.activityAt)} ${DateTimeFormatter.shortTime(item.activityAt)}',
                    maxWidth: maxChipWidth,
                    compact: useTightLayout,
                  ),
                  if (item.hasTotal && item.total != null)
                    _InfoChip(
                      label: CurrencyFormatter.format(item.total!),
                      maxWidth: maxChipWidth,
                      compact: useTightLayout,
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
    this.maxWidth,
    this.compact = false,
  });

  final String label;
  final Color? color;
  final double? maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;
    final horizontalPadding = compact ? AppSpacing.xs : 10.0;
    final verticalPadding = compact ? 4.0 : 6.0;
    final fontSize = compact ? 11.0 : 12.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: chipColor.withValues(alpha: 0.18)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: chipColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}