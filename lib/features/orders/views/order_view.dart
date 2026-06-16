import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/products/product.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets/current_order_panel.dart';
import '../widgets/product_card.dart';
import '../widgets/product_category_sidebar.dart';
import '../widgets/product_detail_sheet.dart';

class OrderView extends StatefulWidget {
  const OrderView({super.key, required this.table});

  final RestaurantTable table;

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  Future<void> _showOrderDetails(
    BuildContext context,
    OrderViewModel viewModel,
  ) async {
    final responsive = AppResponsive.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheetResponsive = AppResponsive.of(sheetContext);
        return FractionallySizedBox(
          heightFactor: sheetResponsive.isPortrait ? 0.88 : 0.94,
          child: CurrentOrderPanel(
            order: viewModel.order,
            tableName: widget.table.name,
            sending: viewModel.isSending,
            responsive: responsive,
            onSendToKitchen: () => viewModel.sendToKitchen(widget.table),
          ),
        );
      },
    );
  }

  Future<void> _showProductDetail(
    BuildContext context,
    OrderViewModel viewModel,
    Product product,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final sheetResponsive = AppResponsive.of(sheetContext);
        return FractionallySizedBox(
          heightFactor: sheetResponsive.isPortrait ? 0.92 : 0.94,
          child: ProductDetailSheet(
            product: product,
            beverages: viewModel.beverageProducts,
            extras: viewModel.extraProducts,
            isPrimaryProduct: viewModel.isPrimaryProduct(product),
            onAdd: (
              selectedProduct,
              quantity,
              complements,
            ) =>
                viewModel.addProductWithSelections(
                  mainProduct: selectedProduct,
                  quantity: quantity,
                  table: widget.table,
                  complements: complements,
                ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderViewModel>().load(widget.table);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, child) {
        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: viewModel.errorMessage != null
              ? ErrorState(
                  message: viewModel.errorMessage!,
                  onRetry: () => viewModel.load(widget.table),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final responsive = AppResponsive.of(
                      context,
                      layoutSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    );
                    final helper = ResponsiveHelper(context);

                    if (!responsive.isPortrait) {
                      return _buildLandscapeContent(
                        context,
                        viewModel,
                        responsive,
                      );
                    }

                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewPaddingOf(context).bottom +
                            helper.percentHeight(0.02),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OrderSummaryButton(
                            order: viewModel.order,
                            onTap: () => _showOrderDetails(context, viewModel),
                          ),
                          SizedBox(height: responsive.spacingMd),
                          SizedBox(
                            height: responsive.categoryButtonHeight + 4,
                            child: ProductCategorySidebar(
                              categories: viewModel.categories,
                              selectedCategory: viewModel.selectedCategory,
                              onSelected: viewModel.selectCategory,
                              responsive: responsive,
                            ),
                          ),
                          SizedBox(height: responsive.spacingLg),
                          ..._buildMobileSections(
                            context,
                            viewModel,
                            responsive,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildLandscapeContent(
    BuildContext context,
    OrderViewModel viewModel,
    AppResponsive responsive,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _OrderSummaryButton(
                order: viewModel.order,
                onTap: () => _showOrderDetails(context, viewModel),
                compact: true,
              ),
              SizedBox(height: responsive.spacingMd),
              SizedBox(
                height: responsive.categoryButtonHeight,
                child: ProductCategorySidebar(
                  categories: viewModel.categories,
                  selectedCategory: viewModel.selectedCategory,
                  onSelected: viewModel.selectCategory,
                  responsive: responsive,
                ),
              ),
              SizedBox(height: responsive.spacingMd),
              Expanded(
                child: GridView.builder(
                  itemCount: viewModel.filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: responsive.productGridColumns,
                    mainAxisSpacing: responsive.spacingMd,
                    crossAxisSpacing: responsive.spacingMd,
                    mainAxisExtent: responsive.productCardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final product = viewModel.filteredProducts[index];
                    return ProductCard(
                      product: product,
                      responsive: responsive,
                      onTap: () => _showProductDetail(context, viewModel, product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMobileSections(
    BuildContext context,
    OrderViewModel viewModel,
    AppResponsive responsive,
  ) {
    switch (viewModel.selectedCategory) {
      case OrderViewModel.mainCategory:
        return [
          _SectionHeader(
            icon: Icons.restaurant_rounded,
            title: 'PLATILLOS',
          ),
          SizedBox(height: responsive.spacingSm),
          _PlatilloCarousel(
            products: viewModel.mainProducts,
            responsive: responsive,
            onTap: (product) => _showProductDetail(context, viewModel, product),
          ),
        ];
      case OrderViewModel.drinksCategory:
        return [
          _SectionHeader(
            icon: Icons.local_drink_rounded,
            title: 'BEBIDAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _BeverageCarousel(
            products: viewModel.beverageProducts,
            onTap: (product) => _showProductDetail(context, viewModel, product),
          ),
        ];
      case OrderViewModel.extrasCategory:
        return [
          _SectionHeader(
            icon: Icons.add_circle_outline_rounded,
            title: 'EXTRAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _ExtraCarousel(
            products: viewModel.extraProducts,
            onTap: (product) => _showProductDetail(context, viewModel, product),
          ),
        ];
      default:
        return [
          _SectionHeader(
            icon: Icons.restaurant_rounded,
            title: 'PLATILLOS',
          ),
          SizedBox(height: responsive.spacingSm),
          _PlatilloCarousel(
            products: viewModel.mainProducts,
            responsive: responsive,
            onTap: (product) => _showProductDetail(context, viewModel, product),
          ),
          SizedBox(height: responsive.spacingLg),
          _SectionHeader(
            icon: Icons.local_drink_rounded,
            title: 'BEBIDAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _BeverageCarousel(
            products: viewModel.beverageProducts,
            onTap: (product) => _showProductDetail(context, viewModel, product),
          ),
          SizedBox(height: responsive.spacingLg),
          _SectionHeader(
            icon: Icons.add_circle_outline_rounded,
            title: 'EXTRAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _ExtraCarousel(
            products: viewModel.extraProducts,
            onTap: (product) => _showProductDetail(context, viewModel, product),
          ),
        ];
    }
  }
}

class _OrderSummaryButton extends StatelessWidget {
  const _OrderSummaryButton({
    required this.order,
    required this.onTap,
    this.compact = false,
  });

  final Order? order;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final itemCount = order?.items.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ) ??
        0;
    final computedTotal = order?.items.fold<double>(
          0,
          (sum, item) => sum + item.total,
        ) ??
        0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: compact ? 16 : 22,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 60 : 68,
                height: compact ? 60 : 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE8CA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primaryAmberDark,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(computedTotal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      itemCount == 1 ? '1 producto' : '$itemCount productos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primaryAmberDark, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        TextButton(
          onPressed: null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryAmber,
            disabledForegroundColor: AppColors.primaryAmber,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todos',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlatilloCarousel extends StatelessWidget {
  const _PlatilloCarousel({
    required this.products,
    required this.responsive,
    required this.onTap,
  });

  final List<Product> products;
  final AppResponsive responsive;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 286,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 170,
            child: ProductCard(
              product: product,
              responsive: responsive,
              onTap: () => onTap(product),
            ),
          );
        },
      ),
    );
  }
}

class _BeverageCarousel extends StatelessWidget {
  const _BeverageCarousel({
    required this.products,
    required this.onTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];
          return _CompactProductCard(
            width: 270,
            product: product,
            icon: Icons.local_drink_rounded,
            onTap: () => onTap(product),
          );
        },
      ),
    );
  }
}

class _ExtraCarousel extends StatelessWidget {
  const _ExtraCarousel({
    required this.products,
    required this.onTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];
          return _CompactProductCard(
            width: 150,
            product: product,
            icon: Icons.add_circle_outline_rounded,
            compact: true,
            onTap: () => onTap(product),
          );
        },
      ),
    );
  }
}

class _CompactProductCard extends StatelessWidget {
  const _CompactProductCard({
    required this.width,
    required this.product,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final double width;
  final Product product;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: compact
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductVisual(icon: icon, compact: compact),
                      const Spacer(),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              CurrencyFormatter.format(product.price),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.primaryAmber,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          _AddCircleButton(onTap: onTap),
                        ],
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _ProductVisual(icon: icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.08,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              CurrencyFormatter.format(product.price),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.primaryAmber,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AddCircleButton(onTap: onTap),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({
    required this.icon,
    this.compact = false,
  });

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 96.0 : 94.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: AppColors.primaryAmberDark,
        size: compact ? 34 : 36,
      ),
    );
  }
}

class _AddCircleButton extends StatelessWidget {
  const _AddCircleButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFBE8CA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.add_rounded,
            color: AppColors.primaryAmberDark,
            size: 30,
          ),
        ),
      ),
    );
  }
}
