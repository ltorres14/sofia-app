import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/activity/recent_activity_item.dart';
import '../../../data/models/products/product.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/recent_activity_card.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets/current_order_panel.dart';
import '../widgets/product_card.dart';
import '../widgets/product_category_card.dart';
import '../widgets/product_category_sidebar.dart';
import '../widgets/product_detail_sheet.dart';

class OrderView extends StatefulWidget {
  const OrderView({super.key, required this.table});

  final RestaurantTable table;

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  Timer? _pollingTimer;
  bool _isSelectionSheetOpen = false;
  String? _lastActionError;

  Future<void> _showOrderDetails(
    BuildContext context,
    OrderViewModel viewModel,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheetResponsive = AppResponsive.of(sheetContext);

        return Builder(
          builder: (panelContext) => Consumer<OrderViewModel>(
            builder: (consumerContext, liveViewModel, child) {
              final selections = liveViewModel.visibleSelections;

              return FractionallySizedBox(
                heightFactor: sheetResponsive.isPortrait ? 0.88 : 0.94,
                child: CurrentOrderPanel(
                  order: liveViewModel.order,
                  visibleSelections: selections,
                  visibleTotal: liveViewModel.visibleTotal,
                  visibleItemCount: liveViewModel.visibleItemCount,
                  tableName: widget.table.name,
                  sending: liveViewModel.isSendingToKitchen,
                  canSendToKitchen: liveViewModel.hasPendingItemsToSend,
                  canEditSelection: liveViewModel.canEditSelection,
                  canEditSelectionComment:
                      liveViewModel.canEditSelectionComment,
                  canDeleteSelection: liveViewModel.canDeleteSelection,
                  statusLabelForSelection:
                      liveViewModel.statusLabelForSelection,
                  onSendToKitchen: () async {
                    if (liveViewModel.isSendingToKitchen) return;
                    final success = await liveViewModel.sendToKitchen();
                    if (!success) return;
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                  },
                  onEditSelection: (selection) => _showEditSelectionDetail(
                    panelContext,
                    liveViewModel,
                    selection.id,
                  ),
                  onSaveSelectionComment: (selection, comment) =>
                      liveViewModel.updateSelectionComment(
                        selection: selection,
                        comment: comment,
                      ),
                  onDeleteSelection: (selection) =>
                      liveViewModel.deleteSelection(selection),
                  resolveProductById: liveViewModel.productById,
                ),
              );
            },
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
    final isPrimaryProduct = viewModel.isPrimaryProduct(product);
    final beverages = isPrimaryProduct
        ? viewModel.beverageProducts
              .where((candidate) => candidate.id != product.id)
              .toList()
        : const <Product>[];
    final extras = isPrimaryProduct
        ? viewModel.extraProducts
              .where((candidate) => candidate.id != product.id)
              .toList()
        : const <Product>[];

    _isSelectionSheetOpen = true;
    final didSave = await showModalBottomSheet<bool>(
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
            beverages: beverages,
            extras: extras,
            isPrimaryProduct: isPrimaryProduct,
            onAdd: (selectedProduct, quantity, complements, comment) async {
              await viewModel.addProductWithSelections(
                mainProduct: selectedProduct,
                quantity: quantity,
                table: widget.table,
                complements: complements,
                comment: comment,
              );
            },
          ),
        );
      },
    );
    _isSelectionSheetOpen = false;

    if (!mounted) return;
    if (didSave == true) {
      await viewModel.refreshCurrentTableOrder();
    }
  }

  Future<void> _showEditSelectionDetail(
    BuildContext context,
    OrderViewModel viewModel,
    int selectionId,
  ) async {
    final selection = viewModel.selectionById(selectionId);
    if (selection == null) return;

    dynamic mainItem;
    for (final item in selection.items) {
      if (item.role == 1) {
        mainItem = item;
        break;
      }
    }

    if (mainItem == null) return;

    final mainProduct = viewModel.productById(mainItem.productId);
    if (mainProduct == null) return;

    final isPrimaryProduct = viewModel.isPrimaryProduct(mainProduct);
    final beverages = isPrimaryProduct
        ? viewModel.beverageProducts
              .where((candidate) => candidate.id != mainProduct.id)
              .toList()
        : const <Product>[];
    final extras = isPrimaryProduct
        ? viewModel.extraProducts
              .where((candidate) => candidate.id != mainProduct.id)
              .toList()
        : const <Product>[];

    final initialComplementQuantities = <int, int>{
      for (final item in selection.items)
        if (item.role != 1) item.productId: item.quantity,
    };

    _isSelectionSheetOpen = true;
    final didSave = await showModalBottomSheet<bool>(
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
            product: mainProduct,
            beverages: beverages,
            extras: extras,
            isPrimaryProduct: isPrimaryProduct,
            editMode: true,
            initialQuantity: mainItem.quantity as int,
            initialComplementQuantities: initialComplementQuantities,
            initialComment: selection.displayComment,
            onAdd: (product, quantity, complements, comment) async {},
            onSaveChanges:
                (selectedProduct, quantity, complements, comment) async {
                  await viewModel.saveSelectionChanges(
                    selection: selection,
                    mainProduct: selectedProduct,
                    quantity: quantity,
                    complements: complements,
                    comment: comment,
                  );
                },
          ),
        );
      },
    );
    _isSelectionSheetOpen = false;

    if (!mounted) return;
    if (didSave == true) {
      await viewModel.refreshCurrentTableOrder();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || _isSelectionSheetOpen) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route?.isCurrent == false) {
        return;
      }

      await context.read<OrderViewModel>().refreshCurrentTableOrder();
    });
  }

  Future<void> _showCategoryProducts(
    BuildContext context,
    OrderViewModel viewModel,
    String categoryName,
    List<Product> products,
  ) async {
    if (products.isEmpty) return;

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
          heightFactor: sheetResponsive.isPortrait ? 0.88 : 0.94,
          child: _CategoryProductsSheet(
            title: categoryName,
            products: products,
            responsive: sheetResponsive,
            onProductTap: (product) {
              Navigator.of(sheetContext).pop();
              _showProductDetail(context, viewModel, product);
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
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.actionErrorMessage == null) {
          _lastActionError = null;
        }

        if (viewModel.actionErrorMessage != null &&
            viewModel.actionErrorMessage != _lastActionError) {
          final actionError = viewModel.actionErrorMessage!;
          _lastActionError = actionError;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(actionError)));

            viewModel.clearActionError();
          });
        }

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

                    return _buildMobileContent(context, viewModel, responsive);
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
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: responsive.scrollBottomSafePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderSummaryButton(
            itemCount: viewModel.visibleItemCount,
            total: viewModel.visibleTotal,
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
          ..._buildMobileSections(context, viewModel, responsive),
          SizedBox(height: responsive.spacingXl),
          _RecentOrderActivitySection(
            items: viewModel.recentActivities,
            isLoading: viewModel.isRecentActivityLoading,
            errorMessage: viewModel.recentActivityErrorMessage,
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
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: responsive.scrollBottomSafePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderSummaryButton(
            itemCount: viewModel.visibleItemCount,
            total: viewModel.visibleTotal,
            onTap: () => _showOrderDetails(context, viewModel),
            compact: true,
          ),
          SizedBox(height: responsive.spacingMd),
          SizedBox(
            height: responsive.landscapeRecentActivitySectionHeight,
            child: _RecentOrderActivitySection(
              items: viewModel.recentActivities,
              isLoading: viewModel.isRecentActivityLoading,
              errorMessage: viewModel.recentActivityErrorMessage,
            ),
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
        ],
      ),
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
          _ProductCategoryList(
            categories: viewModel.foodCategories,
            productsByCategory: viewModel.productsByCategory,
            onTap: (category, products) {
              _showCategoryProducts(context, viewModel, category, products);
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
          _ProductCategoryList(
            categories: viewModel.beverageCategories,
            productsByCategory: viewModel.productsByCategory,
            onTap: (category, products) {
              _showCategoryProducts(context, viewModel, category, products);
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
          _ProductCategoryList(
            categories: viewModel.extraCategories,
            productsByCategory: viewModel.productsByCategory,
            onTap: (category, products) {
              _showCategoryProducts(context, viewModel, category, products);
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
          _ProductCategoryList(
            categories: viewModel.foodCategories,
            productsByCategory: viewModel.productsByCategory,
            onTap: (category, products) {
              _showCategoryProducts(context, viewModel, category, products);
            },
          ),
          SizedBox(height: responsive.spacingLg),
          const _SectionHeader(
            icon: Icons.local_drink_rounded,
            title: 'BEBIDAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _ProductCategoryList(
            categories: viewModel.beverageCategories,
            productsByCategory: viewModel.productsByCategory,
            onTap: (category, products) {
              _showCategoryProducts(context, viewModel, category, products);
            },
          ),
          SizedBox(height: responsive.spacingLg),
          const _SectionHeader(
            icon: Icons.add_circle_outline_rounded,
            title: 'EXTRAS',
          ),
          SizedBox(height: responsive.spacingSm),
          _ProductCategoryList(
            categories: viewModel.extraCategories,
            productsByCategory: viewModel.productsByCategory,
            onTap: (category, products) {
              _showCategoryProducts(context, viewModel, category, products);
            },
          ),
        ];
    }
  }
}

class _ProductCategoryList extends StatelessWidget {
  const _ProductCategoryList({
    required this.categories,
    required this.productsByCategory,
    required this.onTap,
  });

  final List<String> categories;
  final List<Product> Function(String category) productsByCategory;
  final void Function(String category, List<Product> products) onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _EmptyProductsMessage();
    }

    return Column(
      children: [
        for (final category in categories) ...[
          ProductCategoryCard(
            categoryName: category,
            products: productsByCategory(category),
            onTap: () => onTap(category, productsByCategory(category)),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _CategoryProductsSheet extends StatelessWidget {
  const _CategoryProductsSheet({
    required this.title,
    required this.products,
    required this.responsive,
    required this.onProductTap,
  });

  final String title;
  final List<Product> products;
  final AppResponsive responsive;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          responsive.bottomSheetContentPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                Text(
                  products.length == 1
                      ? '1 producto'
                      : '${products.length} productos',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: products.length,
                padding: EdgeInsets.only(
                  bottom: responsive.categorySheetListBottomPadding,
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return ProductCard(
                    product: product,
                    responsive: responsive,
                    onTap: () => onProductTap(product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderActivitySection extends StatelessWidget {
  const _RecentOrderActivitySection({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<RecentActivityItem> items;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial reciente',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: responsive.spacingXs),
        Text(
          'Movimientos de esta mesa y de otras ordenes recientes.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: responsive.spacingSm),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.softBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: responsive.spacingSm),
                  Expanded(
                    child: Text(
                      items.isEmpty
                          ? 'Sin actividad reciente'
                          : 'Ultimos movimientos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage != null && items.isNotEmpty) ...[
                SizedBox(height: responsive.spacingSm),
                _RecentOrderActivityHint(message: errorMessage!),
              ],
              SizedBox(height: responsive.spacingSm),
              if (responsive.isPortrait)
                SizedBox(
                  height: responsive.recentActivityBodyHeight,
                  child: _buildBody(context),
                )
              else
                Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final responsive = AppResponsive.of(context);

    if (isLoading && items.isEmpty) {
      return const _RecentOrderActivityState(
        icon: Icons.sync_rounded,
        message: 'Cargando movimientos recientes...',
      );
    }

    if (items.isEmpty && errorMessage != null) {
      return _RecentOrderActivityState(
        icon: Icons.wifi_off_rounded,
        message: errorMessage!,
      );
    }

    if (items.isNotEmpty) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: responsive.spacingSm),
        itemBuilder: (context, index) {
          return RecentActivityCard(item: items[index], compact: true);
        },
      );
    }

    return const _RecentOrderActivityState(
      icon: Icons.history_rounded,
      message: 'Sin movimientos recientes de ordenes.',
    );
  }
}

class _RecentOrderActivityHint extends StatelessWidget {
  const _RecentOrderActivityHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.16)),
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecentOrderActivityState extends StatelessWidget {
  const _RecentOrderActivityState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryButton extends StatelessWidget {
  const _OrderSummaryButton({
    required this.itemCount,
    required this.total,
    required this.onTap,
    this.compact = false,
  });

  final int itemCount;
  final double total;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(total),
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
  const _SectionHeader({required this.icon, required this.title});

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
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
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

class _EmptyProductsMessage extends StatelessWidget {
  const _EmptyProductsMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'No hay productos disponibles en esta categoria.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
