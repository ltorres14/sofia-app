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
    return showModalBottomSheet<void>(
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
            onAdd: (selectedProduct, quantity, complements) async {
              await viewModel.addProductWithSelections(
                mainProduct: selectedProduct,
                quantity: quantity,
                table: widget.table,
                complements: complements,
              );
            },
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

                    if (!responsive.isPortrait) {
                      return _buildLandscapeContent(
                        context,
                        viewModel,
                        responsive,
                      );
                    }

                    return _buildMobileContent(
                      context,
                      viewModel,
                      responsive,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    OrderViewModel viewModel,
    AppResponsive responsive,
  ) {
    final helper = ResponsiveHelper(context);

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
                      onTap: () {
                        _showProductDetail(context, viewModel, product);
                      },
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
          const _SectionHeader(
            icon: Icons.restaurant_rounded,
            title: 'PLATILLOS',
          ),
          SizedBox(height: responsive.spacingSm),
          _PlatilloCarousel(
            products: viewModel.mainProducts,
            responsive: responsive,
            onTap: (product) {
              _showProductDetail(context, viewModel, product);
            },
          ),
        ];

      case OrderViewModel.drinksCategory:
        return [
          const _SectionHeader(
            icon: Icons.local_drink_rounded,
            title: 'BEBIDAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _BeverageCarousel(
            products: viewModel.beverageProducts,
            onTap: (product) {
              _showProductDetail(context, viewModel, product);
            },
          ),
        ];

      case OrderViewModel.extrasCategory:
        return [
          const _SectionHeader(
            icon: Icons.add_circle_outline_rounded,
            title: 'EXTRAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _ExtraCarousel(
            products: viewModel.extraProducts,
            onTap: (product) {
              _showProductDetail(context, viewModel, product);
            },
          ),
        ];

      default:
        return [
          const _SectionHeader(
            icon: Icons.restaurant_rounded,
            title: 'PLATILLOS',
          ),
          SizedBox(height: responsive.spacingSm),
          _PlatilloCarousel(
            products: viewModel.mainProducts,
            responsive: responsive,
            onTap: (product) {
              _showProductDetail(context, viewModel, product);
            },
          ),
          SizedBox(height: responsive.spacingLg),
          const _SectionHeader(
            icon: Icons.local_drink_rounded,
            title: 'BEBIDAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _BeverageCarousel(
            products: viewModel.beverageProducts,
            onTap: (product) {
              _showProductDetail(context, viewModel, product);
            },
          ),
          SizedBox(height: responsive.spacingLg),
          const _SectionHeader(
            icon: Icons.add_circle_outline_rounded,
            title: 'EXTRAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _ExtraCarousel(
            products: viewModel.extraProducts,
            onTap: (product) {
              _showProductDetail(context, viewModel, product);
            },
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
    final itemCount =
        order?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;

    final computedTotal =
        order?.items.fold<double>(0, (sum, item) => sum + item.total) ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: compact ? 10 : 16,
          ),
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
          child: Row(
            children: [
              Container(
                width: compact ? 28 : 37,
                height: compact ? 28 : 37,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8CC),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primaryAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(computedTotal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        fontSize: compact ? 12 : 20,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itemCount == 1 ? '1 producto' : '$itemCount productos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 12 : 16,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
                size: 36,
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
            color: const Color(0xFFFFF1DE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryAmber,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
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
      return const _EmptyProductsMessage();
    }

    return SizedBox(
      height: 250,
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
      return const _EmptyProductsMessage();
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];

          return _CompactProductCard(
            width: 170,
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
      return const _EmptyProductsMessage();
    }

    return SizedBox(
      height: 220,
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
    final borderRadius = BorderRadius.circular(28);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
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
            padding: const EdgeInsets.all(12),
            child: compact
                ? _CompactVerticalProductContent(
                    product: product,
                    icon: icon,
                    onTap: onTap,
                  )
                : _SmallVerticalProductContent(
                    product: product,
                    icon: icon,
                    onTap: onTap,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SmallVerticalProductContent extends StatelessWidget {
  const _SmallVerticalProductContent({
    required this.product,
    required this.icon,
    required this.onTap,
  });

  final Product product;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductVisual(icon: icon),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 42),
              child: Text(
                CurrencyFormatter.format(product.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryAmber,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _SmallAddCircleButton(onTap: onTap),
        ),
      ],
    );
  }
}

class _CompactVerticalProductContent extends StatelessWidget {
  const _CompactVerticalProductContent({
    required this.product,
    required this.icon,
    required this.onTap,
  });

  final Product product;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductVisual(
              icon: icon,
              compact: true,
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 42),
              child: Text(
                CurrencyFormatter.format(product.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryAmber,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _SmallAddCircleButton(onTap: onTap),
        ),
      ],
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
    final size = compact ? 86.0 : 80.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: AppColors.primaryAmber,
        size: compact ? 32 : 34,
      ),
    );
  }
}

class _SmallAddCircleButton extends StatelessWidget {
  const _SmallAddCircleButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE8CC),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.add_rounded,
            color: AppColors.primaryAmber,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _EmptyProductsMessage extends StatelessWidget {
  const _EmptyProductsMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'No hay productos disponibles en esta categoría.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}