import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/products/product.dart';
import '../../../shared/widgets/safe_app_image.dart';
import '../models/product_selection.dart';

class ProductDetailSheet extends StatefulWidget {
  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.beverages,
    required this.extras,
    required this.onAdd,
    required this.isPrimaryProduct,
  });

  final Product product;
  final List<Product> beverages;
  final List<Product> extras;
  final Future<void> Function(
    Product product,
    int quantity,
    List<ProductSelection> complements,
  )
  onAdd;
  final bool isPrimaryProduct;

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  int _quantity = 1;
  bool _submitting = false;
  final Map<int, int> _complementQuantities = {};

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);
    final total = _calculateTotal();
    final bottomPadding = (responsive.screenHeight * 0.18).clamp(120.0, 180.0);
    final sheetRadius = responsive.productDetailSheetRadius;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.softBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacingLg,
                  responsive.spacingSm,
                  responsive.spacingLg,
                  bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: responsive.isPortrait ? 44 : 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacingLg),
                    _ProductHeroCard(
                      product: widget.product,
                      quantity: _quantity,
                      responsive: responsive,
                      onDecrement: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      onIncrement: () => setState(() => _quantity++),
                    ),
                    if (widget.isPrimaryProduct &&
                        widget.beverages.isNotEmpty) ...[
                      SizedBox(height: responsive.spacingLg),
                      _SectionTitle(
                        title: 'Complementa con bebidas',
                        subtitle: 'Opcional',
                        responsive: responsive,
                      ),
                      SizedBox(height: responsive.spacingSm),
                      ...widget.beverages.map(
                        (product) => _ComplementTile(
                          product: product,
                          quantity: _complementQuantities[product.id] ?? 0,
                          icon: Icons.local_drink_rounded,
                          responsive: responsive,
                          onChanged: (value) =>
                              _updateComplement(product.id, value),
                        ),
                      ),
                    ],
                    if (widget.isPrimaryProduct &&
                        widget.extras.isNotEmpty) ...[
                      SizedBox(height: responsive.spacingLg),
                      _SectionTitle(
                        title: 'Agrega extras',
                        subtitle: 'Opcional',
                        responsive: responsive,
                      ),
                      SizedBox(height: responsive.spacingSm),
                      ...widget.extras.map(
                        (product) => _ComplementTile(
                          product: product,
                          quantity: _complementQuantities[product.id] ?? 0,
                          icon: Icons.add_circle_outline_rounded,
                          responsive: responsive,
                          onChanged: (value) =>
                              _updateComplement(product.id, value),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                responsive.spacingLg,
                responsive.spacingMd,
                responsive.spacingLg,
                responsive.spacingLg,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: Offset(0, -6),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: responsive.orderTitleFontSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: responsive.orderTotalFontSize,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    height: responsive.productDetailFooterButtonHeight,
                    child: FilledButton(
                      onPressed: _submitting ? null : _handleAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: TextStyle(
                          fontSize: responsive.orderBodyFontSize.clamp(
                            15.0,
                            17.0,
                          ),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(_submitting ? 'Agregando...' : 'Agregar'),
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

  void _updateComplement(int productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _complementQuantities.remove(productId);
      } else {
        _complementQuantities[productId] = quantity;
      }
    });
  }

  double _calculateTotal() {
    var total = widget.product.price * _quantity;
    for (final beverage in widget.beverages) {
      total += beverage.price * (_complementQuantities[beverage.id] ?? 0);
    }
    for (final extra in widget.extras) {
      total += extra.price * (_complementQuantities[extra.id] ?? 0);
    }
    return total;
  }

  Future<void> _handleAdd() async {
    setState(() => _submitting = true);
    final selections = [
      ...widget.beverages
          .where((product) => (_complementQuantities[product.id] ?? 0) > 0)
          .map(
            (product) => ProductSelection(
              product: product,
              quantity: _complementQuantities[product.id]!,
            ),
          ),
      ...widget.extras
          .where((product) => (_complementQuantities[product.id] ?? 0) > 0)
          .map(
            (product) => ProductSelection(
              product: product,
              quantity: _complementQuantities[product.id]!,
            ),
          ),
    ];
    await widget.onAdd(widget.product, _quantity, selections);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ProductHeroCard extends StatelessWidget {
  const _ProductHeroCard({
    required this.product,
    required this.quantity,
    required this.responsive,
    required this.onDecrement,
    required this.onIncrement,
  });

  final Product product;
  final int quantity;
  final AppResponsive responsive;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = _resolveProductImage(product);
    final icon = _resolveCategoryIcon(product.category);
    final imageHeight = responsive.productDetailHeroImageHeight;
    final cardRadius = responsive.productDetailSheetRadius;
    final imageRadius = responsive.productListImageRadius + 4;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.productListCardPadding + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: double.infinity,
              height: imageHeight,
              padding: EdgeInsets.all(responsive.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.softBackground,
                borderRadius: BorderRadius.circular(imageRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: SafeAppImage.asset(
                assetPath: imagePath,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(
                  responsive.productListImageRadius,
                ),
                fallbackIcon: icon,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                iconColor: AppColors.primary,
                fit: BoxFit.contain,
                iconSize: responsive.iconSize + 14,
              ),
            ),
          ),
          SizedBox(height: responsive.spacingMd),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: responsive.titleFontSize.clamp(24.0, 30.0),
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacingXs),
          Text(
            CurrencyFormatter.format(product.price),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: responsive.orderTotalFontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: responsive.spacingMd),
          _QuantitySelector(
            label: 'Cantidad',
            quantity: quantity,
            responsive: responsive,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.responsive,
  });

  final String title;
  final String subtitle;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: responsive.orderTitleFontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacingXs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: responsive.captionFontSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ComplementTile extends StatelessWidget {
  const _ComplementTile({
    required this.product,
    required this.quantity,
    required this.icon,
    required this.responsive,
    required this.onChanged,
  });

  final Product product;
  final int quantity;
  final IconData icon;
  final AppResponsive responsive;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageName = product.imageName?.trim();
    final hasImage = imageName != null && imageName.isNotEmpty;
    final imagePath = hasImage ? _resolveProductImage(product) : null;

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacingSm),
      padding: EdgeInsets.all(responsive.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.productListImageRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: responsive.productDetailComplementImageSize,
            height: responsive.productDetailComplementImageSize,
            padding: EdgeInsets.all(responsive.spacingXs + 2),
            decoration: BoxDecoration(
              color: hasImage
                  ? AppColors.softBackground
                  : AppColors.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(
                responsive.productListImageRadius,
              ),
            ),
            child: imagePath != null
                ? SafeAppImage.asset(
                    assetPath: imagePath,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(
                      responsive.productListImageRadius - 4,
                    ),
                    fallbackIcon: icon,
                    backgroundColor: AppColors.secondary.withValues(
                      alpha: 0.16,
                    ),
                    iconColor: AppColors.primary,
                    fit: BoxFit.contain,
                    iconSize: responsive.iconSize + 6,
                  )
                : Icon(
                    icon,
                    color: AppColors.primary,
                    size: responsive.iconSize + 6,
                  ),
          ),
          SizedBox(width: responsive.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: responsive.orderBodyFontSize.clamp(14.0, 16.0),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacingXs),
                Text(
                  CurrencyFormatter.format(product.price),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.orderBodyFontSize.clamp(13.0, 15.0),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.spacingSm),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _InlineCounter(
                quantity: quantity,
                responsive: responsive,
                onDecrement: quantity > 0
                    ? () => onChanged(quantity - 1)
                    : null,
                onIncrement: () => onChanged(quantity + 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.label,
    required this.quantity,
    required this.responsive,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int quantity;
  final AppResponsive responsive;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: responsive.spacingSm,
      spacing: responsive.spacingSm,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: responsive.orderTitleFontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        _InlineCounter(
          quantity: quantity,
          responsive: responsive,
          onDecrement: onDecrement,
          onIncrement: onIncrement,
        ),
      ],
    );
  }
}

class _InlineCounter extends StatelessWidget {
  const _InlineCounter({
    required this.quantity,
    required this.responsive,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final AppResponsive responsive;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final buttonSize = responsive.productDetailCounterButtonSize;
    final textWidth = responsive.isPortrait ? 34.0 : 40.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacingXs,
        vertical: responsive.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CounterButton(
            size: buttonSize,
            icon: Icons.remove_rounded,
            backgroundColor: onDecrement == null
                ? AppColors.border
                : AppColors.secondary.withValues(alpha: 0.12),
            iconColor: onDecrement == null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            onPressed: onDecrement,
          ),
          SizedBox(width: responsive.spacingSm),
          SizedBox(
            width: textWidth,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: responsive.orderTitleFontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: responsive.spacingSm),
          _CounterButton(
            size: buttonSize,
            icon: Icons.add_rounded,
            backgroundColor: AppColors.accent,
            iconColor: AppColors.white,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.size,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  final double size;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: iconColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: size * 0.48),
      ),
    );
  }
}

const String _productImagesBasePath = 'assets/images/businesses/products/';

String _resolveProductImage(Product product) {
  final imageName = product.imageName?.trim();

  if (imageName != null && imageName.isNotEmpty) {
    if (imageName.startsWith('assets/')) {
      return imageName;
    }

    return '$_productImagesBasePath$imageName';
  }

  return _resolveFallbackImage(product.category);
}

String _resolveFallbackImage(String category) {
  final normalized = category.toLowerCase();

  if (normalized.contains('tostada')) {
    return '${_productImagesBasePath}tostada_base.png';
  }

  if (normalized.contains('tostito')) {
    return '${_productImagesBasePath}tostitos_base.png';
  }

  if (normalized.contains('cóctel') || normalized.contains('coctel')) {
    return '${_productImagesBasePath}coctel_camaron_base.png';
  }

  if (normalized.contains('aguachile')) {
    return '${_productImagesBasePath}aguachile_base.png';
  }

  if (normalized.contains('ceviche') || normalized.contains('especial')) {
    return '${_productImagesBasePath}ceviche_base.png';
  }

  if (normalized.contains('chicharron') || normalized.contains('chicharrón')) {
    return '${_productImagesBasePath}chicharron_pescado_base.png';
  }

  return '${_productImagesBasePath}tostada_base.png';
}

IconData _resolveCategoryIcon(String category) {
  final normalized = category.toLowerCase();

  if (normalized.contains('bebida')) {
    return Icons.local_drink_rounded;
  }

  if (normalized.contains('extra')) {
    return Icons.add_circle_outline_rounded;
  }

  return Icons.restaurant_rounded;
}
