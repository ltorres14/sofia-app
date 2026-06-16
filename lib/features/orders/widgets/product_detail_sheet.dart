import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/products/product.dart';
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
  ) onAdd;
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
    final responsiveHelper = ResponsiveHelper(context);
    final theme = Theme.of(context);
    final total = _calculateTotal();

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  responsiveHelper.percentHeight(0.16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton.filledTonal(
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.textPrimary,
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.product.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(widget.product.price),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryAmberDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _QuantitySelector(
                            label: 'Cantidad',
                            quantity: _quantity,
                            onDecrement: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            onIncrement: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isPrimaryProduct &&
                        widget.beverages.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: 'Complementa con bebidas',
                        subtitle: 'Opcional',
                      ),
                      const SizedBox(height: 10),
                      ...widget.beverages.map(
                        (product) => _ComplementTile(
                          product: product,
                          quantity: _complementQuantities[product.id] ?? 0,
                          icon: Icons.local_drink_rounded,
                          onChanged: (value) => _updateComplement(
                            product.id,
                            value,
                          ),
                        ),
                      ),
                    ],
                    if (widget.isPrimaryProduct && widget.extras.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: 'Agrega extras',
                        subtitle: 'Opcional',
                      ),
                      const SizedBox(height: 10),
                      ...widget.extras.map(
                        (product) => _ComplementTile(
                          product: product,
                          quantity: _complementQuantities[product.id] ?? 0,
                          icon: Icons.add_circle_outline_rounded,
                          onChanged: (value) => _updateComplement(
                            product.id,
                            value,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryAmberDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _submitting ? null : _handleAdd,
                      child: Text(
                        'Agregar - ${CurrencyFormatter.format(total)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
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
    required this.onChanged,
  });

  final Product product;
  final int quantity;
  final IconData icon;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryAmberDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(product.price),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _InlineCounter(
            quantity: quantity,
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
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        _InlineCounter(
          quantity: quantity,
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
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.textPrimary,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.primaryAmberDark,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
