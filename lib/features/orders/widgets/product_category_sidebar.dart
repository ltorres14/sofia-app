import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';

class ProductCategorySidebar extends StatelessWidget {
  const ProductCategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    required this.responsive,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = responsive.isPortrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.separated(
          scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
          padding: EdgeInsets.symmetric(
            horizontal: isHorizontal ? 2 : responsive.spacingSm,
            vertical: isHorizontal ? 4 : responsive.spacingSm,
          ),
          itemCount: categories.length,
          separatorBuilder: (_, _) => SizedBox(
            width: isHorizontal ? responsive.spacingSm : 0,
            height: isHorizontal ? 0 : responsive.spacingSm,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final selected = category == selectedCategory;
            final icon = _resolveIcon(category);
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isHorizontal ? 82 : 0,
                maxWidth: isHorizontal
                    ? (constraints.maxWidth * 0.34).clamp(98.0, 154.0)
                    : double.infinity,
              ),
              child: SizedBox(
                height: isHorizontal
                    ? responsive.categoryButtonHeight - 4
                    : responsive.categoryButtonHeight,
                child: OutlinedButton(
                  onPressed: () => onSelected(category),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        selected ? AppColors.primaryAmber : Colors.white,
                    foregroundColor:
                        selected ? Colors.white : AppColors.textPrimary,
                    side: BorderSide(
                      color:
                          selected ? AppColors.primaryAmber : AppColors.border,
                    ),
                    minimumSize: Size(
                      isHorizontal ? 0 : double.infinity,
                      responsive.categoryButtonHeight,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacingSm,
                      vertical: responsive.spacingXs,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.categoryButtonFontSize - 0.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _resolveIcon(String category) {
    switch (category) {
      case 'Todos':
        return Icons.grid_view_rounded;
      case 'Platillos':
        return Icons.restaurant_rounded;
      case 'Bebidas':
        return Icons.local_drink_rounded;
      case 'Extras':
        return Icons.add_circle_outline_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
