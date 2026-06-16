import 'package:flutter/material.dart';

import '../../../core/config/business_config.dart';
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

  final Product product;
  final AppResponsive responsive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMobilePortrait = responsive.isPortrait && !responsive.isTablet;

    final contentPadding = isMobilePortrait
        ? responsive.spacingXs + 2
        : responsive.spacingMd;

    final buttonHeight = isMobilePortrait
        ? responsive.orderActionButtonHeight.clamp(36, 40).toDouble()
        : responsive.orderActionButtonHeight;

    final headerIcon = _resolveCategoryIcon(product.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageHeight = isMobilePortrait
                  ? (constraints.maxHeight * 0.26).clamp(56.0, 70.0)
                  : (constraints.maxHeight * 0.38).clamp(82.0, 112.0);

              return Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              headerIcon,
                              color: AppColors.primaryAmber,
                              size: isMobilePortrait
                                  ? responsive.iconSize
                                  : responsive.iconSize + 2,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: imageHeight - 8,
                            child: SafeAppImage.asset(
                              assetPath: BusinessConfig
                                  .current.placeholderProductAssetPath,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(14),
                              fallbackIcon: headerIcon,
                              fit: BoxFit.contain,
                              iconSize: isMobilePortrait
                                  ? responsive.iconSize + 4
                                  : responsive.iconSize + 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacingXs + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: isMobilePortrait ? 14 : 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          SizedBox(height: responsive.spacingXs / 2),
                          Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: responsive.captionFontSize - 1,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontSize: isMobilePortrait ? 16 : 17,
                                      color: AppColors.primaryAmber,
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacingXs + 2),
                    SizedBox(
                      height: buttonHeight,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacingSm,
                            vertical: responsive.spacingXs,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFFFE8CC),
                          foregroundColor: AppColors.primaryAmber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(
                          Icons.add_rounded,
                          size: isMobilePortrait
                              ? responsive.iconSize - 4
                              : responsive.iconSize - 2,
                        ),
                        label: Text(
                          'Agregar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobilePortrait
                                ? responsive.orderBodyFontSize - 1
                                : responsive.orderBodyFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _resolveCategoryIcon(String category) {
    final normalized = category.toLowerCase();

    if (normalized.contains('bebida') || normalized.contains('drink')) {
      return Icons.local_drink_rounded;
    }

    if (normalized.contains('extra') || normalized.contains('complemento')) {
      return Icons.add_circle_outline_rounded;
    }

    return Icons.restaurant_rounded;
  }
}