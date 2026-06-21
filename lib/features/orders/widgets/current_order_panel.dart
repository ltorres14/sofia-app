import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/orders/order_selection.dart';
import '../../../data/models/products/product.dart';
import '../../../shared/widgets/safe_app_image.dart';
import 'order_item_row.dart';

class CurrentOrderPanel extends StatelessWidget {
  const CurrentOrderPanel({
    super.key,
    required this.order,
    required this.visibleSelections,
    required this.visibleTotal,
    required this.visibleItemCount,
    required this.tableName,
    required this.onSendToKitchen,
    required this.onEditSelection,
    required this.onDeleteSelection,
    required this.resolveProductById,
    required this.sending,
    required this.responsive,
  });

  final Order? order;
  final List<OrderSelection> visibleSelections;
  final double visibleTotal;
  final int visibleItemCount;
  final String tableName;
  final Future<void> Function() onSendToKitchen;
  final Future<void> Function(OrderSelection selection) onEditSelection;
  final void Function(OrderSelection selection) onDeleteSelection;
  final Product? Function(int productId) resolveProductById;
  final bool sending;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selections = visibleSelections;
    final hasSelections = selections.isNotEmpty;
    final legacyItems = order?.items ?? const [];
    final itemCount = hasSelections
        ? selections.length
        : legacyItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final computedTotal = hasSelections
        ? visibleTotal
        : (order?.total ??
              legacyItems.fold<double>(0, (sum, item) => sum + item.total));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.productListCardPadding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.productListCardRadius,
                ),
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
                children: [
                  Container(
                    width: responsive.productListImageSize,
                    height: responsive.productListImageSize,
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
                          'Orden actual',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: responsive.orderTitleFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacingXs / 2),
                        Text(
                          tableName,
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
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacingSm,
                      vertical: responsive.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      hasSelections
                          ? (itemCount == 1
                                ? '1 seleccion'
                                : '$itemCount selecciones')
                          : (itemCount == 1 ? '1 item' : '$itemCount items'),
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                child: order == null || (!hasSelections && legacyItems.isEmpty)
                    ? Center(
                        child: Text(
                          'Aun no hay productos agregados.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: responsive.orderBodyFontSize,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : hasSelections
                    ? ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: responsive.spacingSm),
                        itemCount: selections.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: responsive.spacingSm),
                        itemBuilder: (context, index) => _SelectionCard(
                          selection: selections[index],
                          responsive: responsive,
                          onEdit: () => onEditSelection(selections[index]),
                          onDelete: () => _confirmDeleteSelection(
                            context,
                            selections[index],
                          ),
                          resolveProductById: resolveProductById,
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: responsive.spacingSm),
                        itemCount: legacyItems.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: responsive.spacingSm),
                        itemBuilder: (context, index) => OrderItemRow(
                          item: legacyItems[index],
                          responsive: responsive,
                          showActions: false,
                        ),
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                responsive.spacingLg,
                responsive.spacingMd,
                responsive.spacingLg,
                responsive.spacingLg,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 22,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: responsive.orderTitleFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(computedTotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: responsive.orderTotalFontSize,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacingMd),
                  SizedBox(
                    height: responsive.orderActionButtonHeight,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: sending ? null : () => onSendToKitchen(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.55,
                        ),
                        disabledForegroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: TextStyle(
                          fontSize: responsive.orderBodyFontSize.clamp(
                            15.0,
                            17.0,
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Enviar a Cocina'),
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

  Future<void> _confirmDeleteSelection(
    BuildContext context,
    OrderSelection selection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        ),
        title: Text(
          'Eliminar selección',
          style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
            fontSize: responsive.orderTitleFontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar esta selección?',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
            fontSize: responsive.orderBodyFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          responsive.spacingXl,
          0,
          responsive.spacingXl,
          responsive.spacingXl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size(96, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDeleteSelection(selection);
    }
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.selection,
    required this.responsive,
    required this.onEdit,
    required this.onDelete,
    required this.resolveProductById,
  });

  final OrderSelection selection;
  final AppResponsive responsive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Product? Function(int productId) resolveProductById;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        child: Ink(
          padding: EdgeInsets.all(responsive.productListCardPadding),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(
              responsive.productListCardRadius,
            ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selection.label.isNotEmpty
                          ? selection.label
                          : 'Seleccion ${selection.sequenceNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: responsive.orderTitleFontSize,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacingSm),
                  _SelectionActionButton(
                    icon: Icons.edit_outlined,
                    responsive: responsive,
                    onPressed: onEdit,
                  ),
                  SizedBox(width: responsive.spacingSm),
                  _SelectionActionButton(
                    icon: Icons.delete_outline_rounded,
                    responsive: responsive,
                    onPressed: onDelete,
                  ),
                  SizedBox(width: responsive.spacingSm),
                  Text(
                    CurrencyFormatter.format(selection.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.orderBodyFontSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if ((selection.notes ?? '').trim().isNotEmpty) ...[
                SizedBox(height: responsive.spacingXs),
                Text(
                  selection.notes!.trim(),
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: responsive.spacingSm),
              ..._buildItems(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final sortedItems = List.of(selection.items)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));

    return [
      for (var index = 0; index < sortedItems.length; index++) ...[
        _SelectionItemRow(
          product: resolveProductById(sortedItems[index].productId),
          productName: sortedItems[index].productName,
          quantity: sortedItems[index].quantity,
          unitPrice: sortedItems[index].unitPrice,
          total: sortedItems[index].total,
          roleLabel: _roleLabel(sortedItems[index].role),
          responsive: responsive,
        ),
        if (index < sortedItems.length - 1)
          SizedBox(height: responsive.spacingSm),
      ],
    ];
  }

  String _roleLabel(int role) {
    switch (role) {
      case 1:
        return 'Platillo principal';
      case 2:
        return 'Bebida';
      case 3:
      default:
        return 'Extra';
    }
  }
}


class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.icon,
    required this.responsive,
    required this.onPressed,
  });

  final IconData icon;
  final AppResponsive responsive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonSize = responsive.productDetailCounterButtonSize
        .clamp(44.0, 48.0)
        .toDouble();

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: Size(buttonSize, buttonSize),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          icon,
          size: responsive.iconSize.clamp(22.0, 26.0),
        ),
      ),
    );
  }
}

class _SelectionItemRow extends StatelessWidget {
  const _SelectionItemRow({
    required this.product,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.roleLabel,
    required this.responsive,
  });

  final Product? product;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;
  final String roleLabel;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imagePath = _resolveSelectionItemImage(product, roleLabel, productName);
    final fallbackIcon = _resolveSelectionItemIcon(roleLabel);

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
              fallbackIcon: fallbackIcon,
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
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: responsive.spacingXs / 2),
                Text(
                  productName,
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
                  quantity == 1 ? '1x' : '${quantity}x',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.captionFontSize,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: responsive.spacingXs / 2),
                Text(
                  '${CurrencyFormatter.format(unitPrice)} c/u',
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
                CurrencyFormatter.format(total),
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
    );
  }
}

const String _productImagesBasePath = 'assets/images/businesses/products/';

String _resolveSelectionItemImage(
  Product? product,
  String roleLabel,
  String productName,
) {
  final imageName = product?.imageName?.trim();

  if (imageName != null && imageName.isNotEmpty) {
    if (imageName.startsWith('assets/')) {
      return imageName;
    }

    return '$_productImagesBasePath$imageName';
  }

  final normalizedRole = roleLabel.toLowerCase();
  final normalizedName = productName.toLowerCase();
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

  if (value.contains('cóctel') || value.contains('coctel')) {
    return '${_productImagesBasePath}coctel_camaron_base.png';
  }

  if (value.contains('aguachile')) {
    return '${_productImagesBasePath}aguachile_base.png';
  }

  if (value.contains('chicharron') || value.contains('chicharrón')) {
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
