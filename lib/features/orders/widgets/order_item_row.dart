import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(responsive.productListCardPadding),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: responsive.productListImageSize.clamp(52.0, 64.0),
                  height: responsive.productListImageSize.clamp(52.0, 64.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1E6),
                    borderRadius: BorderRadius.circular(
                      responsive.productListImageRadius,
                    ),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.orderBodyFontSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: responsive.orderBodyFontSize,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsive.spacingXs),
                      Text(
                        '${CurrencyFormatter.format(item.unitPrice)} c/u',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: responsive.captionFontSize,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
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
                      'Total',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: responsive.captionFontSize,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: responsive.spacingXs / 2),
                    Text(
                      CurrencyFormatter.format(item.total),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: responsive.orderBodyFontSize,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
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
