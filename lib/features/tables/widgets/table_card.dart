import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
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
        ? Colors.red
        : table.hasOrder
        ? Colors.orange
        : Colors.green;
    final label = table.waitingPayment
        ? 'Esperando pago'
        : table.hasOrder
        ? 'Con orden'
        : 'Libre';
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: responsive.isPortrait
          ? (responsive.bodyFontSize + 2).clamp(16, 20).toDouble()
          : (responsive.bodyFontSize + 3).clamp(17, 22).toDouble(),
      fontWeight: FontWeight.w700,
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(responsive.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.table_restaurant_rounded,
                    color: color,
                    size: responsive.iconSize + 4,
                  ),
                  SizedBox(width: responsive.spacingSm),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: responsive.captionFontSize,
                            ),
                          ),
                          side: BorderSide.none,
                          backgroundColor: color.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                table.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              SizedBox(height: responsive.spacingXs),
              Text(
                'Toca para abrir orden o revisar mesa',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.captionFontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
