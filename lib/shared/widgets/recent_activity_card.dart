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
    final presentation = _RecentActivityPresentation.fromItem(item);
    final cardWidth = compact
        ? (responsive.isTablet
              ? 308.0
              : responsive.screenWidth.clamp(268.0, 292.0))
        : responsive.isTablet
        ? 336.0
        : responsive.screenWidth.clamp(296.0, 332.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = compact || constraints.maxHeight <= 180;
        final horizontalPadding = useCompactLayout
            ? responsive.spacingMd.clamp(12.0, 14.0)
            : responsive.spacingMd.clamp(14.0, 18.0);
        final verticalPadding = useCompactLayout
            ? responsive.spacingSm.clamp(10.0, 12.0)
            : responsive.spacingMd.clamp(14.0, 18.0);
        final iconContainerSize = useCompactLayout ? 36.0 : 44.0;
        final iconSize = useCompactLayout ? 18.0 : 22.0;
        final titleFontSize = useCompactLayout
            ? responsive.bodyFontSize.clamp(13.0, 14.0)
            : responsive.bodyFontSize.clamp(15.0, 16.5);
        final metaFontSize = useCompactLayout
            ? responsive.captionFontSize.clamp(11.0, 12.0)
            : responsive.captionFontSize.clamp(12.0, 13.0);
        final primaryFontSize = useCompactLayout
            ? responsive.bodyFontSize.clamp(13.0, 14.0)
            : responsive.bodyFontSize.clamp(15.0, 16.0);
        final summaryFontSize = useCompactLayout
            ? responsive.captionFontSize.clamp(11.0, 12.0)
            : responsive.bodyFontSize.clamp(13.0, 14.0);
        final headerGap = useCompactLayout ? 10.0 : 12.0;
        final contentGap = useCompactLayout ? 6.0 : 8.0;
        final footerGap = useCompactLayout
            ? responsive.spacingSm.clamp(8.0, 10.0)
            : responsive.spacingSm;
        final maxChipWidth =
            (cardWidth - (horizontalPadding * 2)) *
            (useCompactLayout ? 0.72 : 0.78);
        final timestampLabel = useCompactLayout
            ? _compactTimestampLabel(item.activityAt)
            : '${DateTimeFormatter.shortDate(item.activityAt)} ${DateTimeFormatter.shortTime(item.activityAt)}';

        return Container(
          width: cardWidth,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(useCompactLayout ? 24.0 : 26.0),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: presentation.accentColor.withValues(alpha: 0.14),
                      border: Border.all(
                        color: presentation.accentColor.withValues(alpha: 0.18),
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: presentation.accentColor.withValues(
                            alpha: 0.10,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      presentation.icon,
                      color: presentation.accentColor,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: headerGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          presentation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        if (presentation.subtitle != null) ...[
                          SizedBox(height: useCompactLayout ? 2.0 : 4.0),
                          Text(
                            presentation.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: metaFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (presentation.primaryText != null) ...[
                SizedBox(height: contentGap),
                Text(
                  presentation.primaryText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: primaryFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
              ],
              if (presentation.summaryText != null) ...[
                SizedBox(height: useCompactLayout ? 4.0 : contentGap),
                Text(
                  presentation.summaryText!,
                  maxLines: useCompactLayout ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: summaryFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
              if (presentation.commentText != null) ...[
                SizedBox(height: contentGap),
                _CommentBlock(
                  comment: presentation.commentText!,
                  compact: useCompactLayout,
                  accentColor: presentation.accentColor,
                ),
              ],
              if (useCompactLayout)
                const Spacer()
              else
                SizedBox(height: footerGap),
              if (useCompactLayout)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _InfoChip(
                    label: timestampLabel,
                    icon: Icons.schedule_rounded,
                    maxWidth: cardWidth - (horizontalPadding * 2),
                    compact: true,
                  ),
                )
              else
                Wrap(
                  spacing: footerGap,
                  runSpacing: footerGap,
                  children: [
                    _InfoChip(
                      label: timestampLabel,
                      icon: Icons.schedule_rounded,
                      maxWidth: maxChipWidth,
                    ),
                    if (presentation.statusLabel != null)
                      _InfoChip(
                        label: presentation.statusLabel!,
                        icon: Icons.flag_rounded,
                        color: _statusColor(presentation.statusLabel!),
                        maxWidth: maxChipWidth,
                      ),
                    if (presentation.paymentMethod != null)
                      _InfoChip(
                        label: presentation.paymentMethod!,
                        icon: Icons.payments_outlined,
                        color: AppColors.primary,
                        maxWidth: maxChipWidth,
                      ),
                    if (presentation.showTotalChip)
                      _InfoChip(
                        label: CurrencyFormatter.format(item.total!),
                        icon: Icons.attach_money_rounded,
                        color: AppColors.success,
                        maxWidth: maxChipWidth,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
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

  String _compactTimestampLabel(DateTime value) {
    final localValue = value.toLocal();
    final now = DateTime.now().toLocal();

    if (DateUtils.isSameDay(localValue, now)) {
      return DateTimeFormatter.shortTime(localValue);
    }

    return DateTimeFormatter.shortDate(localValue);
  }
}

class _CommentBlock extends StatelessWidget {
  const _CommentBlock({
    required this.comment,
    required this.compact,
    required this.accentColor,
  });

  final String comment;
  final bool compact;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10.0 : 12.0,
        vertical: compact ? 7.0 : 10.0,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(compact ? 14.0 : 16.0),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.mode_comment_outlined,
            color: accentColor,
            size: compact ? 14.0 : 16.0,
          ),
          SizedBox(width: compact ? 6.0 : 8.0),
          Expanded(
            child: Text(
              comment,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    this.color,
    this.maxWidth,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final double? maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;
    final horizontalPadding = compact ? 8.0 : 10.0;
    final verticalPadding = compact ? 5.0 : 6.0;
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
          border: Border.all(color: chipColor.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 12.0 : 14.0, color: chipColor),
            SizedBox(width: compact ? 4.0 : 6.0),
            Flexible(
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
          ],
        ),
      ),
    );
  }
}

class _RecentActivityPresentation {
  const _RecentActivityPresentation({
    required this.title,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.primaryText,
    this.summaryText,
    this.commentText,
    this.paymentMethod,
    this.statusLabel,
    this.showTotalChip = false,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final String? primaryText;
  final String? summaryText;
  final String? commentText;
  final String? paymentMethod;
  final String? statusLabel;
  final bool showTotalChip;

  factory _RecentActivityPresentation.fromItem(RecentActivityItem item) {
    final group = item.normalizedEventGroup;
    final type = item.normalizedEventType;
    final fallbackDescription = _meaningfulText(item.description);
    final subtitle = _joinMeta([
      item.tableName,
      if (item.hasActorName) item.actorName,
    ]);

    switch (group) {
      case 'selection':
        final title = _selectionTitle(type);
        final selectionLabel = item.hasSelectionLabel
            ? _prefixSelectionSequence(
                item.selectionLabel!,
                item.selectionSequenceNumber,
              )
            : null;
        final primaryText = _firstMeaningful([
          selectionLabel,
          item.itemsSummary,
          _dedupedValue(fallbackDescription, excluded: {title}),
        ]);

        return _RecentActivityPresentation(
          title: title,
          icon: _iconForType(type, group),
          accentColor: _accentColorForType(type, group),
          subtitle: subtitle,
          primaryText: primaryText,
          summaryText: _firstMeaningful([
            _dedupedValue(item.itemsSummary, excluded: {primaryText}),
            _dedupedValue(fallbackDescription, excluded: {title, primaryText}),
          ]),
          commentText: item.selectionComment,
          statusLabel: _resolveStatusLabel(item, title),
        );
      case 'kitchen':
        final title = _kitchenTitle(type);
        final primaryText = _firstMeaningful([
          item.itemsSummary,
          _dedupedValue(fallbackDescription, excluded: {title}),
        ]);

        return _RecentActivityPresentation(
          title: title,
          icon: _iconForType(type, group),
          accentColor: _accentColorForType(type, group),
          subtitle: subtitle,
          primaryText: primaryText,
          summaryText: _dedupedValue(
            fallbackDescription,
            excluded: {title, primaryText},
          ),
          statusLabel: _resolveStatusLabel(item, title),
        );
      case 'table':
        const title = 'Orden abierta';
        final primaryText = _firstMeaningful([
          item.itemsSummary,
          _dedupedValue(fallbackDescription, excluded: {title}),
        ]);

        return _RecentActivityPresentation(
          title: title,
          icon: _iconForType(type, group),
          accentColor: _accentColorForType(type, group),
          subtitle: subtitle,
          primaryText: primaryText,
          summaryText: _dedupedValue(
            fallbackDescription,
            excluded: {title, primaryText},
          ),
        );
      case 'billing':
        const title = 'Cuenta solicitada';
        final primaryText = _firstMeaningful([
          item.itemsSummary,
          _dedupedValue(fallbackDescription, excluded: {title}),
        ]);

        return _RecentActivityPresentation(
          title: title,
          icon: _iconForType(type, group),
          accentColor: _accentColorForType(type, group),
          subtitle: subtitle,
          primaryText: primaryText,
          summaryText: _dedupedValue(
            fallbackDescription,
            excluded: {title, primaryText},
          ),
          showTotalChip: item.hasMeaningfulTotal,
        );
      case 'payment':
        const title = 'Pago registrado';
        final primaryText = _firstMeaningful([
          item.itemsSummary,
          _dedupedValue(fallbackDescription, excluded: {title}),
        ]);

        return _RecentActivityPresentation(
          title: title,
          icon: _iconForType(type, group),
          accentColor: _accentColorForType(type, group),
          subtitle: subtitle,
          primaryText: primaryText,
          summaryText: _firstMeaningful([
            _dedupedValue(item.paymentMethod, excluded: {primaryText}),
            _dedupedValue(fallbackDescription, excluded: {title, primaryText}),
          ]),
          commentText: item.paymentComments,
          paymentMethod: item.paymentMethod,
          showTotalChip: item.hasMeaningfulTotal,
        );
      default:
        final title =
            _firstMeaningful([_dedupedValue(fallbackDescription)]) ??
            'Movimiento reciente';
        final selectionLabel = item.hasSelectionLabel
            ? _prefixSelectionSequence(
                item.selectionLabel!,
                item.selectionSequenceNumber,
              )
            : null;
        final primaryText = _firstMeaningful([
          selectionLabel,
          item.itemsSummary,
          _dedupedValue(fallbackDescription, excluded: {title}),
        ]);

        return _RecentActivityPresentation(
          title: title,
          icon: _iconForType(type, group),
          accentColor: _accentColorForType(type, group),
          subtitle: subtitle,
          primaryText: primaryText,
          summaryText: _firstMeaningful([
            _dedupedValue(item.itemsSummary, excluded: {primaryText}),
            _dedupedValue(fallbackDescription, excluded: {title, primaryText}),
          ]),
          commentText: _firstMeaningful([
            item.selectionComment,
            item.paymentComments,
          ]),
          paymentMethod: item.paymentMethod,
          statusLabel: _resolveStatusLabel(item, title),
          showTotalChip: item.hasMeaningfulTotal,
        );
    }
  }

  static String _selectionTitle(String type) {
    switch (type) {
      case 'order_selection_created':
        return 'Nueva selección';
      case 'order_selection_updated':
        return 'Selección editada';
      case 'order_selection_comment_updated':
        return 'Comentario actualizado';
      case 'order_selection_cancelled':
        return 'Selección cancelada';
      default:
        return 'Movimiento de selección';
    }
  }

  static String _kitchenTitle(String type) {
    switch (type) {
      case 'order_sent_to_kitchen':
      case 'kitchen_ticket_sent':
        return 'Enviado a cocina';
      case 'kitchen_ticket_preparing':
        return 'En preparación';
      case 'kitchen_ticket_ready':
        return 'Listo';
      case 'kitchen_ticket_status_updated':
        return 'Cocina actualizada';
      default:
        return 'Movimiento de cocina';
    }
  }

  static IconData _iconForType(String type, String group) {
    switch (type) {
      case 'order_selection_created':
        return Icons.playlist_add_circle_rounded;
      case 'order_selection_updated':
        return Icons.edit_note_rounded;
      case 'order_selection_comment_updated':
        return Icons.mode_comment_rounded;
      case 'order_selection_cancelled':
        return Icons.remove_circle_outline_rounded;
      case 'order_sent_to_kitchen':
      case 'kitchen_ticket_sent':
        return Icons.restaurant_rounded;
      case 'kitchen_ticket_preparing':
        return Icons.local_fire_department_rounded;
      case 'kitchen_ticket_ready':
        return Icons.check_circle_rounded;
      case 'kitchen_ticket_status_updated':
        return Icons.task_alt_rounded;
      case 'order_opened':
        return Icons.table_bar_rounded;
      case 'order_bill_requested':
        return Icons.receipt_long_rounded;
      case 'order_paid':
        return Icons.payments_rounded;
      default:
        switch (group) {
          case 'selection':
            return Icons.restaurant_menu_rounded;
          case 'kitchen':
            return Icons.restaurant_rounded;
          case 'table':
            return Icons.table_bar_rounded;
          case 'billing':
            return Icons.receipt_long_rounded;
          case 'payment':
            return Icons.payments_rounded;
          default:
            return Icons.history_rounded;
        }
    }
  }

  static Color _accentColorForType(String type, String group) {
    switch (group) {
      case 'selection':
        return AppColors.accent;
      case 'kitchen':
        return AppColors.warning;
      case 'table':
        return AppColors.primary;
      case 'billing':
        return AppColors.warning;
      case 'payment':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }

  static String? _joinMeta(List<String?> values) {
    final normalized = values
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized.join(' • ');
  }

  static String? _prefixSelectionSequence(String label, int? sequenceNumber) {
    final normalizedLabel = _meaningfulText(label);
    if (normalizedLabel == null) {
      return null;
    }

    if (sequenceNumber == null) {
      return normalizedLabel;
    }

    return '#$sequenceNumber $normalizedLabel';
  }

  static String? _resolveStatusLabel(RecentActivityItem item, String title) {
    if (!item.hasStatus) {
      return null;
    }

    final normalizedStatus = item.statusLabel!.trim().toLowerCase();
    final normalizedTitle = title.trim().toLowerCase();
    if (normalizedStatus.isEmpty ||
        normalizedStatus == normalizedTitle ||
        normalizedTitle.contains(normalizedStatus) ||
        normalizedStatus.contains(normalizedTitle)) {
      return null;
    }

    return item.statusLabel;
  }

  static String? _dedupedValue(
    String? value, {
    Set<String?> excluded = const {},
  }) {
    final normalized = _meaningfulText(value);
    if (normalized == null) {
      return null;
    }

    for (final candidate in excluded) {
      final excludedValue = _meaningfulText(candidate);
      if (excludedValue != null &&
          excludedValue.toLowerCase() == normalized.toLowerCase()) {
        return null;
      }
    }

    return normalized;
  }

  static String? _meaningfulText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String? _firstMeaningful(List<String?> values) {
    for (final value in values) {
      final normalized = _meaningfulText(value);
      if (normalized != null) {
        return normalized;
      }
    }

    return null;
  }
}
