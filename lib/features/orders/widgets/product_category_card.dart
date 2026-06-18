import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/products/product.dart';
import '../../../shared/widgets/safe_app_image.dart';

class ProductCategoryCard extends StatelessWidget {
  const ProductCategoryCard({
    super.key,
    required this.categoryName,
    required this.products,
    required this.onTap,
  });

  final String categoryName;
  final List<Product> products;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePath = _resolveCategoryImage(categoryName);
    final icon = _resolveCategoryIcon(categoryName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
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
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F1E6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: SafeAppImage.asset(
                    assetPath: imagePath,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(16),
                    fallbackIcon: icon,
                    fit: BoxFit.contain,
                    iconSize: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        products.length == 1
                            ? '1 producto'
                            : '${products.length} productos',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 34,
                  color: AppColors.primaryAmber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveCategoryImage(String category) {
    final normalized = category.toLowerCase();

    if (normalized.contains('tostada')) {
      return 'assets/images/businesses/products/tostada_base.png';
    }

    if (normalized.contains('tostito')) {
      return 'assets/images/businesses/products/tostitos_base.png';
    }

    if (normalized.contains('cóctel') ||
        normalized.contains('coctel')) {
      return 'assets/images/businesses/products/coctel_camaron_base.png';
    }

    if (normalized.contains('especial')) {
      return 'assets/images/businesses/products/ceviche_base.png';
    }

    if (normalized.contains('bebida')) {
      return 'assets/images/businesses/products/coctel_camaron_base.png';
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