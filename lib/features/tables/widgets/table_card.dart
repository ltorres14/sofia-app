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
  });

  final RestaurantTable table;
  final AppResponsive responsive;
  final VoidCallback onTap;

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
                // Icono mesa arriba izquierda
                Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    color: color,
                    size: 22,
                  ),
                ),

                // Chip estado arriba derecha
                Positioned(
                  top: 0,
                  right: 0,
                  child: _StatusChip(
                    label: label,
                    color: color,
                  ),
                ),

                // Nombre mesa
                Positioned(
                  left: 0,
                  bottom: 32,
                  child: Text(
                    table.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.05,
                        ),
                  ),
                ),

                // Indicador inferior SIEMPRE visible
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: _BottomIndicator(
                    color: color,
                    icon: table.waitingPayment
                        ? Icons.payments_rounded
                        : table.hasOrder
                            ? Icons.receipt_long_rounded
                            : Icons.event_seat_rounded,
                    text: table.hasOrder ? '1' : null,
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
  const _StatusChip({
    required this.label,
    required this.color,
  });

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
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
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

class _BottomIndicator extends StatelessWidget {
  const _BottomIndicator({
    required this.color,
    required this.icon,
    this.text,
  });

  final Color color;
  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          if (text != null) ...[
            const SizedBox(width: 4),
            Text(
              text!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}