import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../shared/layouts/pos_shell.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets/current_order_panel.dart';
import '../widgets/product_card.dart';
import '../widgets/product_category_sidebar.dart';

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
          child: PosShell(
            title: 'Orden en ${widget.table.name}',
            subtitle: 'Toma de orden',
            trailing: _OrderSummaryButton(
              tableName: widget.table.name,
              order: viewModel.order,
              responsive: AppResponsive.of(context),
              onTap: () => _showOrderDetails(context, viewModel),
            ),
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
                      final isMobilePortrait =
                          responsive.isPortrait && !responsive.isTablet;
                      final gridSpacing = isMobilePortrait
                          ? responsive.spacingSm
                          : responsive.spacingMd;
                      final gridPadding = EdgeInsets.only(
                        bottom: isMobilePortrait
                            ? responsive.spacingXs
                            : responsive.spacingSm,
                      );
                      final gridDelegate = isMobilePortrait
                          ? SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: gridSpacing,
                              crossAxisSpacing: gridSpacing,
                              mainAxisExtent: 188,
                            )
                          : SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: responsive.productGridColumns,
                              mainAxisSpacing: responsive.spacingMd,
                              crossAxisSpacing: responsive.spacingMd,
                              mainAxisExtent: responsive.productCardHeight,
                            );

                      if (responsive.orderLayoutDirection == Axis.vertical) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: responsive.categoryButtonHeight +
                                  (isMobilePortrait
                                      ? responsive.spacingMd
                                      : responsive.spacingSm * 2),
                              child: ProductCategorySidebar(
                                categories: viewModel.categories,
                                selectedCategory: viewModel.selectedCategory,
                                onSelected: viewModel.selectCategory,
                                responsive: responsive,
                              ),
                            ),
                            SizedBox(height: responsive.panelGap),
                            Expanded(
                              child: GridView.builder(
                                padding: gridPadding,
                                itemCount: viewModel.filteredProducts.length,
                                gridDelegate: gridDelegate,
                                itemBuilder: (context, index) {
                                  final product =
                                      viewModel.filteredProducts[index];
                                  return ProductCard(
                                    product: product,
                                    responsive: responsive,
                                    onAdd: () => viewModel.addProduct(
                                      product,
                                      widget.table,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width:
                                responsive.availableWidth *
                                responsive.categoryPanelWidthPercent,
                            child: ProductCategorySidebar(
                              categories: viewModel.categories,
                              selectedCategory: viewModel.selectedCategory,
                              onSelected: viewModel.selectCategory,
                              responsive: responsive,
                            ),
                          ),
                          SizedBox(width: responsive.panelGap),
                          Expanded(
                            child: GridView.builder(
                              padding: gridPadding,
                              itemCount: viewModel.filteredProducts.length,
                              gridDelegate: gridDelegate,
                              itemBuilder: (context, index) {
                                final product =
                                    viewModel.filteredProducts[index];
                                return ProductCard(
                                  product: product,
                                  responsive: responsive,
                                  onAdd: () => viewModel.addProduct(
                                    product,
                                    widget.table,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: responsive.panelGap),
                          SizedBox(
                            width: responsive.orderPanelWidth,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: _OrderSummaryButton(
                                tableName: widget.table.name,
                                order: viewModel.order,
                                responsive: responsive,
                                expanded: true,
                                onTap: () => _showOrderDetails(context, viewModel),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _OrderSummaryButton extends StatelessWidget {
  const _OrderSummaryButton({
    required this.tableName,
    required this.order,
    required this.responsive,
    required this.onTap,
    this.expanded = false,
  });

  final String tableName;
  final Order? order;
  final AppResponsive responsive;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCompact = responsive.isPortrait && !expanded;
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
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        child: Ink(
          width: expanded ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? responsive.spacingXs : responsive.spacingSm,
            vertical: isCompact ? responsive.spacingXs : responsive.spacingSm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: isCompact ? responsive.iconSize - 2 : responsive.iconSize,
                color: colorScheme.primary,
              ),
              SizedBox(width: isCompact ? responsive.spacingXs : responsive.spacingSm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.format(computedTotal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isCompact
                            ? responsive.orderBodyFontSize + 2
                            : responsive.orderTitleFontSize,
                      ),
                    ),
                    SizedBox(height: responsive.spacingXs / 2),
                    Text(
                      itemCount == 1
                          ? '1 item'
                          : '$itemCount items',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: isCompact
                            ? responsive.captionFontSize - 1
                            : responsive.captionFontSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!responsive.isPortrait || expanded) ...[
                SizedBox(width: responsive.spacingSm),
                Flexible(
                  child: Text(
                    tableName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: responsive.captionFontSize,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
