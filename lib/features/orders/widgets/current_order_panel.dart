import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order.dart';
import 'order_item_row.dart';

class CurrentOrderPanel extends StatelessWidget {
  const CurrentOrderPanel({
    super.key,
    required this.order,
    required this.tableName,
    required this.onSendToKitchen,
    required this.sending,
    required this.responsive,
  });

  final Order? order;
  final String tableName;
  final Future<void> Function() onSendToKitchen;
  final bool sending;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final itemCount = order?.items.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ) ??
        0;
    final computedTotal = order?.items.fold<double>(
          0,
          (sum, item) => sum + item.total,
        ) ??
        0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacingSm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surfaceContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(responsive.spacingSm),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: responsive.iconSize,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: responsive.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden actual',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: responsive.orderTitleFontSize,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: responsive.spacingXs / 2),
                        Text(
                          tableName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: responsive.captionFontSize,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacingSm,
                      vertical: responsive.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Text(
                      itemCount == 1 ? '1 item' : '$itemCount items',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacingMd),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.spacingSm),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: order == null || order!.items.isEmpty
                    ? Center(
                        child: Text(
                          'Aun no hay productos agregados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.orderBodyFontSize,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: order!.items.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: responsive.spacingSm),
                        itemBuilder: (context, index) => OrderItemRow(
                          item: order!.items[index],
                          responsive: responsive,
                          showActions: true,
                        ),
                      ),
              ),
            ),
            SizedBox(height: responsive.spacingMd),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacingSm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de la orden',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: responsive.spacingXs / 2),
                  Text(
                    CurrencyFormatter.format(computedTotal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineSmall?.copyWith(
                      fontSize: responsive.orderTotalFontSize + 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: responsive.spacingSm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          label: const Text('Editar qty'),
                        ),
                      ),
                      SizedBox(width: responsive.spacingSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Eliminar'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacingSm),
                  SizedBox(
                    height: responsive.orderActionButtonHeight,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: sending ? null : () => onSendToKitchen(),
                      icon: Icon(Icons.send_rounded, size: responsive.iconSize),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Enviar a Cocina',
                          style: TextStyle(
                            fontSize: responsive.orderBodyFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
