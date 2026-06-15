import 'package:flutter/material.dart';

import '../../../core/config/business_config.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/products/product.dart';
import '../../../shared/widgets/safe_app_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.responsive,
    required this.onAdd,
  });

  final Product product;
  final AppResponsive responsive;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isMobilePortrait = responsive.isPortrait && !responsive.isTablet;
    final contentPadding = isMobilePortrait
        ? responsive.spacingXs + 2
        : responsive.spacingMd;
    final buttonHeight = isMobilePortrait
        ? responsive.orderActionButtonHeight.clamp(36, 40).toDouble()
        : responsive.orderActionButtonHeight;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = isMobilePortrait
              ? (constraints.maxHeight * 0.24).clamp(52.0, 66.0)
              : (constraints.maxHeight * 0.38).clamp(82.0, 112.0);

          return Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: SafeAppImage.asset(
                    assetPath: BusinessConfig.current.placeholderProductAssetPath,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(12),
                    fallbackIcon: Icons.fastfood_rounded,
                    iconSize: isMobilePortrait
                        ? responsive.iconSize - 1
                        : responsive.iconSize + 6,
                  ),
                ),
                SizedBox(height: responsive.spacingXs + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: isMobilePortrait
                              ? responsive.orderBodyFontSize - 1
                              : responsive.orderBodyFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: responsive.spacingXs / 2),
                      Text(
                        CurrencyFormatter.format(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isMobilePortrait
                              ? responsive.captionFontSize - 1
                              : responsive.captionFontSize,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacingXs + 2),
                SizedBox(
                  height: buttonHeight,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacingSm,
                        vertical: responsive.spacingXs,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      Icons.add_rounded,
                      size: isMobilePortrait
                          ? responsive.iconSize - 3
                          : responsive.iconSize,
                    ),
                    label: Text(
                      'Agregar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobilePortrait
                            ? responsive.orderBodyFontSize - 2
                            : responsive.orderBodyFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
