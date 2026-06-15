import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order_item.dart';

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.item,
    required this.responsive,
    this.showActions = false,
  });

  final OrderItem item;
  final AppResponsive responsive;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(responsive.spacingSm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: responsive.isPortrait ? 44 : 50,
                  height: responsive.isPortrait ? 44 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: TextStyle(
                      fontSize: responsive.orderBodyFontSize,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: responsive.orderBodyFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: responsive.spacingXs / 2),
                      Text(
                        '${CurrencyFormatter.format(item.unitPrice)} c/u',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: responsive.captionFontSize,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: responsive.spacingSm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.total),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: responsive.orderBodyFontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (showActions) ...[
              SizedBox(height: responsive.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('Qty'),
                  ),
                  SizedBox(width: responsive.spacingXs),
                  TextButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Quitar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
