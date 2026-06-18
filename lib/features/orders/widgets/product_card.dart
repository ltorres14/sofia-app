import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/products/product.dart';
import '../../../shared/widgets/safe_app_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.responsive,
    required this.onTap,
  });

  static const String _productImagesBasePath =
      'assets/images/businesses/products/';

  final Product product;
  final AppResponsive responsive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = _resolveProductImage(product);
    final icon = _resolveCategoryIcon(product.category);

    final cardRadius = responsive.productListCardRadius;
    final cardPadding = responsive.productListCardPadding;
    final imageSize = responsive.productListImageSize;
    final imagePadding = responsive.productListImagePadding;
    final imageRadius = responsive.productListImageRadius;
    final addButtonSize = responsive.productListAddButtonSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: responsive.productListCardMinHeight,
          ),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
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
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                children: [
                  Container(
                    width: imageSize,
                    height: imageSize,
                    padding: EdgeInsets.all(imagePadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1E6),
                      borderRadius: BorderRadius.circular(imageRadius),
                    ),
                    child: SafeAppImage.asset(
                      assetPath: imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(
                        (imageRadius - 6).clamp(12, 18),
                      ),
                      fallbackIcon: icon,
                      fit: BoxFit.contain,
                      iconSize: responsive.iconSize + 8,
                    ),
                  ),
                  SizedBox(width: responsive.spacingMd),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.productListNameFontSize,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacingXs),
                        Text(
                          CurrencyFormatter.format(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.productListPriceFontSize,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: responsive.spacingSm),
                  SizedBox(
                    width: addButtonSize,
                    height: addButtonSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: addButtonSize * 0.60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
      return 'assets/images/businesses/products/tostada_base.png';
    }

    if (normalized.contains('tostito')) {
      return 'assets/images/businesses/products/tostitos_base.png';
    }

    if (normalized.contains('cóctel') || normalized.contains('coctel')) {
      return 'assets/images/businesses/products/coctel_camaron_base.png';
    }

    if (normalized.contains('aguachile')) {
      return 'assets/images/businesses/products/aguachile_base.png';
    }

    if (normalized.contains('ceviche') || normalized.contains('especial')) {
      return 'assets/images/businesses/products/ceviche_base.png';
    }

    if (normalized.contains('chicharron') ||
        normalized.contains('chicharrón')) {
      return 'assets/images/businesses/products/chicharron_pescado_base.png';
    }

    return 'assets/images/businesses/products/tostada_base.png';
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
}