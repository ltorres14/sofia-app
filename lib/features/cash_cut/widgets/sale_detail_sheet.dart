import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cash_cut/today_sales.dart';
import '../../../shared/widgets/safe_app_image.dart';

class SaleDetailSheet extends StatelessWidget {
  const SaleDetailSheet({super.key, required this.sale});

  final TodaySale sale;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          responsive.spacingMd,
          12,
          responsive.spacingMd,
          responsive.bottomSheetContentPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            SizedBox(height: responsive.spacingMd),
            _SaleDetailHeaderCard(sale: sale, responsive: responsive),
            SizedBox(height: responsive.spacingMd),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  responsive.spacingSm,
                  responsive.spacingSm,
                  responsive.spacingSm,
                  responsive.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softBackground,
                  borderRadius: BorderRadius.circular(
                    responsive.productListCardRadius,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: sale.hasDetailAvailable
                    ? ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: responsive.spacingSm),
                        itemCount: sale.selections.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: responsive.spacingSm),
                        itemBuilder: (context, index) {
                          return _SaleSelectionDetailCard(
                            selection: sale.selections[index],
                            responsive: responsive,
                          );
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: EdgeInsets.all(responsive.spacingLg),
                          child: Text(
                            'No hay detalle disponible para esta venta.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: responsive.orderBodyFontSize,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(height: responsive.spacingMd),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacingLg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 22,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total cobrado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: responsive.orderTitleFontSize,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(sale.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: responsive.orderTotalFontSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
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

class _SaleDetailHeaderCard extends StatelessWidget {
  const _SaleDetailHeaderCard({required this.sale, required this.responsive});

  final TodaySale sale;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final methodVisual = _paymentMethodVisual(sale.paymentMethod);
    final cashierName = sale.cashierName?.trim() ?? '';

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: responsive.productListImageSize.clamp(56.0, 68.0),
                height: responsive.productListImageSize.clamp(56.0, 68.0),
                padding: EdgeInsets.all(responsive.productListImagePadding),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E6),
                  borderRadius: BorderRadius.circular(
                    responsive.productListImageRadius,
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: responsive.iconSize,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: responsive.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.displayTableName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: responsive.orderTitleFontSize,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacingXs / 2),
                    Text(
                      'Orden #${sale.orderId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: responsive.captionFontSize,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsive.spacingSm),
              Text(
                CurrencyFormatter.format(sale.total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: responsive.orderBodyFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacingMd),
          Wrap(
            spacing: responsive.spacingSm,
            runSpacing: responsive.spacingSm,
            children: [
              _SaleMetaChip(icon: methodVisual.icon, label: methodVisual.label),
              _SaleMetaChip(
                icon: Icons.schedule_rounded,
                label: _formatTime(sale.paidAt),
              ),
              if (cashierName.isNotEmpty)
                _SaleMetaChip(
                  icon: Icons.point_of_sale_rounded,
                  label: cashierName,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    return DateFormat('h:mm a').format(value.toLocal()).toUpperCase();
  }
}

class _SaleMetaChip extends StatelessWidget {
  const _SaleMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleSelectionDetailCard extends StatelessWidget {
  const _SaleSelectionDetailCard({
    required this.selection,
    required this.responsive,
  });

  final TodaySaleSelection selection;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final items = selection.visibleItems;

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  selection.displayLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: responsive.orderTitleFontSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: responsive.spacingSm),
              Text(
                CurrencyFormatter.format(selection.total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: responsive.orderBodyFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (selection.displayComment.isNotEmpty) ...[
            SizedBox(height: responsive.spacingSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                selection.displayComment,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          SizedBox(height: responsive.spacingSm),
          if (items.isEmpty)
            Text(
              'No hay items visibles en esta seleccion.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: responsive.captionFontSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            for (var index = 0; index < items.length; index++) ...[
              SaleItemRow(item: items[index], responsive: responsive),
              if (index < items.length - 1)
                SizedBox(height: responsive.spacingSm),
            ],
          ],
        ],
      ),
    );
  }
}

class SaleItemRow extends StatelessWidget {
  const SaleItemRow({super.key, required this.item, required this.responsive});

  final TodaySaleSelectionItem item;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final imagePath = _resolveSelectionItemImage(item);

    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: responsive.productListImageSize.clamp(52.0, 64.0),
            height: responsive.productListImageSize.clamp(52.0, 64.0),
            padding: EdgeInsets.all(responsive.spacingXs + 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E6),
              borderRadius: BorderRadius.circular(
                responsive.productListImageRadius,
              ),
            ),
            child: SafeAppImage.asset(
              assetPath: imagePath,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(
                responsive.productListImageRadius - 6,
              ),
              fallbackIcon: _resolveSelectionItemIcon(item.roleLabel),
              fit: BoxFit.contain,
              iconSize: responsive.iconSize + 4,
              iconColor: AppColors.primary,
              backgroundColor: const Color(0xFFF7F1E6),
            ),
          ),
          SizedBox(width: responsive.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: responsive.spacingXs / 2),
                Text(
                  item.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: responsive.orderBodyFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacingXs),
                Text(
                  item.quantity == 1 ? '1x' : '${item.quantity}x',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: responsive.spacingXs / 2),
                Text(
                  '${CurrencyFormatter.format(item.unitPrice)} c/u',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                'Subtotal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: responsive.orderBodyFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodVisual {
  const _MethodVisual({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

_MethodVisual _paymentMethodVisual(String method) {
  switch (method.trim().toLowerCase()) {
    case 'cash':
      return const _MethodVisual(
        label: 'Efectivo',
        icon: Icons.payments_rounded,
      );
    case 'card':
      return const _MethodVisual(
        label: 'Tarjeta',
        icon: Icons.credit_card_rounded,
      );
    case 'transfer':
      return const _MethodVisual(
        label: 'Transferencia',
        icon: Icons.account_balance_rounded,
      );
    case 'mixed':
      return const _MethodVisual(
        label: 'Mixto',
        icon: Icons.account_balance_wallet_rounded,
      );
    case 'other':
    default:
      return const _MethodVisual(label: 'Otro', icon: Icons.more_horiz_rounded);
  }
}

const String _productImagesBasePath = 'assets/images/businesses/products/';

String _resolveSelectionItemImage(TodaySaleSelectionItem item) {
  final imageName = item.imageName?.trim();

  if (imageName != null && imageName.isNotEmpty) {
    if (imageName.startsWith('assets/')) {
      return imageName;
    }

    return '$_productImagesBasePath$imageName';
  }

  final normalizedRole = item.roleLabel.toLowerCase();
  final normalizedName = item.displayName.toLowerCase();
  final value = '$normalizedRole $normalizedName';

  if (value.contains('bebida') ||
      value.contains('agua') ||
      value.contains('refresco')) {
    return '${_productImagesBasePath}refresco_base.png';
  }

  if (value.contains('extra') ||
      value.contains('aderezo') ||
      value.contains('tostada extra') ||
      value.contains('tostadas')) {
    return '${_productImagesBasePath}tostadas_extras_base.png';
  }

  if (value.contains('tostada')) {
    return '${_productImagesBasePath}tostada_base.png';
  }

  if (value.contains('tostito')) {
    return '${_productImagesBasePath}tostitos_base.png';
  }

  if (value.contains('coctel')) {
    return '${_productImagesBasePath}coctel_camaron_base.png';
  }

  if (value.contains('aguachile')) {
    return '${_productImagesBasePath}aguachile_base.png';
  }

  if (value.contains('chicharron')) {
    return '${_productImagesBasePath}chicharron_pescado_base.png';
  }

  if (value.contains('ceviche') || value.contains('especial')) {
    return '${_productImagesBasePath}ceviche_base.png';
  }

  return '${_productImagesBasePath}tostada_base.png';
}

IconData _resolveSelectionItemIcon(String roleLabel) {
  final normalizedRole = roleLabel.toLowerCase();

  if (normalizedRole.contains('bebida')) {
    return Icons.local_drink_rounded;
  }

  if (normalizedRole.contains('extra')) {
    return Icons.add_circle_outline_rounded;
  }

  return Icons.restaurant_rounded;
}
