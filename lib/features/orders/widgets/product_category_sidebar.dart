import 'package:flutter/material.dart';

class ProductCategorySidebar extends StatelessWidget {
  const ProductCategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return FilledButton.tonalIcon(
            onPressed: () => onSelected(category),
            style: FilledButton.styleFrom(
              backgroundColor: selected ? Theme.of(context).colorScheme.primary : null,
              foregroundColor: selected ? Colors.white : null,
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.category_rounded),
            label: Text(category),
          );
        },
      ),
    );
  }
}
