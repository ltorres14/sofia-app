import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/tables/restaurant_table.dart';

class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.table,
    required this.responsive,
    required this.onTap,
    this.draftSelectionCount,
  });

  final RestaurantTable table;
  final AppResponsive responsive;
  final VoidCallback onTap;
  final int? draftSelectionCount;

  @override
  Widget build(BuildContext context) {
    final color = table.waitingPayment
        ? AppColors.tableWaitingPayment
        : table.hasOrder
        ? AppColors.tableWithOrder
        : AppColors.tableFree;

    final label = table.waitingPayment
        ? 'Esperando pago'
        : table.hasOrder
        ? 'Con orden'
        : 'Libre';

    final selectionCount = draftSelectionCount ?? table.activeOrdersCount;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x127C4A12),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: _StatusChip(label: label, color: color),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        table.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      _SelectionsSummary(
                        count: selectionCount,
                        color: const Color.fromARGB(255, 36, 24, 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SelectionsSummary extends StatelessWidget {
  const _SelectionsSummary({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortText = '🍽️ $count';
        final fullText = switch (count) {
          0 => '🍽️ Sin selecciones',
          1 => '🍽️ 1 selección',
          _ => '🍽️ $count selecciones',
        };

        final compact = constraints.maxWidth < 110;

        return Text(
          compact ? shortText : fullText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: compact ? 11 : 12,
            color: color,
            fontWeight: FontWeight.w700,
            height: 0.5,
          ),
        );
      },
    );
  }
}