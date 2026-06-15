import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            child: viewModel.errorMessage != null
                ? ErrorState(
                    message: viewModel.errorMessage!,
                    onRetry: () => viewModel.load(widget.table),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: ProductCategorySidebar(
                          categories: viewModel.categories,
                          selectedCategory: viewModel.selectedCategory,
                          onSelected: viewModel.selectCategory,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: GridView.builder(
                          itemCount: viewModel.filteredProducts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (context, index) {
                            final product = viewModel.filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onAdd: () => viewModel.addProduct(product, widget.table),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 340,
                        child: CurrentOrderPanel(
                          order: viewModel.order,
                          sending: viewModel.isSending,
                          onSendToKitchen: () => viewModel.sendToKitchen(widget.table),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
