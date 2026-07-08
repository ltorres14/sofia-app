import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/products/product.dart';
import '../../../shared/widgets/safe_app_image.dart';
import '../../../shared/widgets/sofia_bottom_sheet_header.dart';
import '../models/product_selection.dart';

class ProductDetailSheet extends StatefulWidget {
  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.beverages,
    required this.extras,
    required this.onAdd,
    required this.isPrimaryProduct,
    this.editMode = false,
    this.initialQuantity,
    this.initialComplementQuantities,
    this.initialComment,
    this.onSaveChanges,
  });

  final Product product;
  final List<Product> beverages;
  final List<Product> extras;
  final Future<void> Function(
    Product product,
    int quantity,
    List<ProductSelection> complements,
    String comment,
  )
  onAdd;
  final bool isPrimaryProduct;
  final bool editMode;
  final int? initialQuantity;
  final Map<int, int>? initialComplementQuantities;
  final String? initialComment;
  final Future<void> Function(
    Product product,
    int quantity,
    List<ProductSelection> complements,
    String comment,
  )?
  onSaveChanges;

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  int _quantity = 1;
  bool _submitting = false;
  final Map<int, int> _complementQuantities = {};
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity ?? 1;
    _complementQuantities.addAll(
      widget.initialComplementQuantities ?? const {},
    );
    _commentController = TextEditingController(
      text: widget.initialComment?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final theme = Theme.of(context);
    final total = _calculateTotal();
    final sheetRadius = responsive.productDetailSheetRadius;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.softBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: responsive.spacingSm,
                  bottom: responsive.spacingMd,
                ),
                child: SofiaBottomSheetHeader(
                  title: widget.editMode
                      ? 'Editar seleccion'
                      : 'Agregar producto',
                  showHandle: true,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    responsive.spacingLg,
                    0,
                    responsive.spacingLg,
                    MediaQuery.viewInsetsOf(context).bottom +
                        responsive.spacingLg,
                  ),
                  children: [
                    _ProductHeroCard(
                      product: widget.product,
                      quantity: _quantity,
                      responsive: responsive,
                      onDecrement: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      onIncrement: () => setState(() => _quantity++),
                    ),
                    SizedBox(height: responsive.spacingLg),
                    _CommentCard(
                      controller: _commentController,
                      responsive: responsive,
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
                      SizedBox(height: responsive.spacingMd),
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
              Container(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacingLg,
                  responsive.spacingMd,
                  responsive.spacingLg,
                  responsive.spacingLg,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: responsive.orderTitleFontSize,
                              fontWeight: FontWeight.w900,
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
                        child: Text(
                          _submitting
                              ? (widget.editMode
                                    ? 'Guardando...'
                                    : 'Agregando...')
                              : (widget.editMode
                                    ? 'Guardar cambios'
                                    : 'Agregar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final comment = _commentController.text.trim();

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

    try {
      if (widget.editMode && widget.onSaveChanges != null) {
        await widget.onSaveChanges!(
          widget.product,
          _quantity,
          selections,
          comment,
        );
      } else {
        await widget.onAdd(widget.product, _quantity, selections, comment);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.controller, required this.responsive});

  final TextEditingController controller;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(responsive.productListCardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comentario para cocina',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: responsive.orderTitleFontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacingXs),
          Text(
            'Opcional. Agrega instrucciones para esta seleccion.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: responsive.captionFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacingSm),
          TextFormField(
            controller: controller,
            minLines: 3,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom + 140,
            ),
            decoration: InputDecoration(
              hintText: 'Ej. sin cebolla, salsa aparte o bien dorado',
              filled: true,
              fillColor: AppColors.softBackground,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
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
    final cardRadius = responsive.productListCardRadius;
    final imageRadius = responsive.productListImageRadius;
    final imageHeight = responsive.isPortrait
        ? (responsive.screenHeight * 0.15).clamp(112.0, 138.0)
        : responsive.productDetailHeroImageHeight;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.productListCardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(cardRadius),
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
          Container(
            width: double.infinity,
            height: imageHeight,
            padding: EdgeInsets.all(responsive.spacingSm),
            decoration: BoxDecoration(
              color: _productImageBackground,
              borderRadius: BorderRadius.circular(imageRadius),
            ),
            child: SafeAppImage.asset(
              assetPath: imagePath,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(imageRadius - 6),
              fallbackIcon: icon,
              fit: BoxFit.contain,
              iconSize: responsive.iconSize + 14,
              iconColor: AppColors.primary,
              backgroundColor: _productImageBackground,
            ),
          ),
          SizedBox(height: responsive.spacingMd),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: responsive.isPortrait
                  ? responsive.productListNameFontSize.clamp(18.0, 22.0)
                  : responsive.titleFontSize.clamp(24.0, 30.0),
              fontWeight: FontWeight.w900,
              height: 1.08,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacingXs),
          Text(
            CurrencyFormatter.format(product.price),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: responsive.productListPriceFontSize.clamp(19.0, 24.0),
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacingXs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: responsive.orderTitleFontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacingSm,
              vertical: responsive.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: responsive.captionFontSize,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
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
    final imagePath = _resolveProductImage(product);
    final imageSize = responsive.isPortrait
        ? responsive.productDetailComplementImageSize.clamp(62.0, 76.0)
        : responsive.productDetailComplementImageSize.clamp(64.0, 82.0);

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacingSm),
      padding: EdgeInsets.all(
        responsive.isPortrait ? responsive.spacingSm : responsive.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.productListCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            padding: EdgeInsets.all(responsive.spacingXs + 2),
            decoration: BoxDecoration(
              color: _productImageBackground,
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
              fallbackIcon: icon,
              backgroundColor: _productImageBackground,
              iconColor: AppColors.primary,
              fit: BoxFit.contain,
              iconSize: responsive.iconSize + 4,
            ),
          ),
          SizedBox(width: responsive.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: responsive.orderBodyFontSize.clamp(14.0, 16.0),
                    fontWeight: FontWeight.w900,
                    height: 1.15,
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
          _InlineCounter(
            quantity: quantity,
            responsive: responsive,
            compact: true,
            onDecrement: quantity > 0 ? () => onChanged(quantity - 1) : null,
            onIncrement: () => onChanged(quantity + 1),
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

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: responsive.orderTitleFontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
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
    this.compact = false,
  });

  final int quantity;
  final AppResponsive responsive;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact
        ? responsive.productDetailCounterButtonSize.clamp(34.0, 38.0)
        : responsive.productDetailCounterButtonSize;
    final textWidth = compact ? 24.0 : 34.0;
    final spacing = compact ? 4.0 : responsive.spacingSm;

    return Container(
      padding: EdgeInsets.all(compact ? 4 : responsive.spacingXs),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
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
                : AppColors.secondary.withValues(alpha: 0.22),
            iconColor: onDecrement == null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            onPressed: onDecrement,
          ),
          SizedBox(width: spacing),
          SizedBox(
            width: textWidth,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: compact
                    ? responsive.orderBodyFontSize.clamp(13.0, 15.0)
                    : responsive.orderTitleFontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: spacing),
          _CounterButton(
            size: buttonSize,
            icon: Icons.add_rounded,
            backgroundColor: AppColors.primary,
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
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: iconColor,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: size * 0.5),
      ),
    );
  }
}

const String _productImagesBasePath = 'assets/images/businesses/products/';
const Color _productImageBackground = Color(0xFFF7F1E6);

String _resolveProductImage(Product product) {
  final imageName = product.imageName?.trim();

  if (imageName != null && imageName.isNotEmpty) {
    if (imageName.startsWith('assets/')) {
      return imageName;
    }

    return '$_productImagesBasePath$imageName';
  }

  return _resolveFallbackImage(product.category, product.name);
}

String _resolveFallbackImage(String category, [String? productName]) {
  final normalizedCategory = category.toLowerCase();
  final normalizedName = (productName ?? '').toLowerCase();
  final value = '$normalizedCategory $normalizedName';

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
