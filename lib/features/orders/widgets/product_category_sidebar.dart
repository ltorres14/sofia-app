import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';

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
    final horizontalPadding = isHorizontal
        ? responsive.spacingXs
        : responsive.spacingSm;
    final verticalPadding = isHorizontal
        ? responsive.spacingXs
        : responsive.spacingSm;

    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.separated(
            scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            itemCount: categories.length,
            separatorBuilder: (_, _) => SizedBox(
              width: isHorizontal ? responsive.spacingSm : 0,
              height: isHorizontal ? 0 : responsive.spacingSm,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = category == selectedCategory;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isHorizontal ? 92 : 0,
                  maxWidth: isHorizontal
                      ? (constraints.maxWidth * 0.32).clamp(110.0, 168.0)
                      : double.infinity,
                ),
                child: SizedBox(
                  height: responsive.categoryButtonHeight,
                  child: FilledButton.tonal(
                    onPressed: () => onSelected(category),
                    style: FilledButton.styleFrom(
                      backgroundColor: selected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: selected ? Colors.white : null,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: responsive.categoryButtonFontSize,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
