import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../cash_cut/widgets/cash_cut_summary_card.dart';
import '../viewmodels/payment_view_model.dart';
import '../widgets/payment_method_button.dart';
import '../widgets/payment_summary_card.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final _tableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewModel>().load();
    });
  }

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentViewModel>(
      builder: (context, viewModel, child) {
        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: viewModel.errorMessage != null
              ? ErrorState(
                  message: viewModel.errorMessage!,
                  onRetry: viewModel.load,
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Buscar orden por mesa',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _tableController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Número de mesa',
                                      prefixIcon: Icon(Icons.search_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        final tableId = int.tryParse(
                                          _tableController.text,
                                        );
                                        if (tableId != null) {
                                          viewModel.loadOrderByTable(tableId);
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.receipt_long_rounded,
                                      ),
                                      label: const Text('Cargar orden'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: PaymentSummaryCard(
                              total: viewModel.activeOrder?.total ?? 0,
                              orderId: viewModel.activeOrder?.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Método de pago',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  PaymentMethodButton(
                                    label: 'Efectivo',
                                    icon: Icons.payments_rounded,
                                    selected: viewModel.selectedMethod == 1,
                                    onTap: () => viewModel.selectMethod(1),
                                  ),
                                  const SizedBox(height: 12),
                                  PaymentMethodButton(
                                    label: 'Tarjeta',
                                    icon: Icons.credit_card_rounded,
                                    selected: viewModel.selectedMethod == 2,
                                    onTap: () => viewModel.selectMethod(2),
                                  ),
                                  const SizedBox(height: 12),
                                  PaymentMethodButton(
                                    label: 'Transferencia',
                                    icon: Icons.account_balance_rounded,
                                    selected: viewModel.selectedMethod == 3,
                                    onTap: () => viewModel.selectMethod(3),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: viewModel.activeOrder == null
                                          ? null
                                          : viewModel.payCurrentOrder,
                                      icon: const Icon(
                                        Icons.point_of_sale_rounded,
                                      ),
                                      label: Text(
                                        'Cobrar ${CurrencyFormatter.format(viewModel.activeOrder?.total ?? 0)}',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: CashCutSummaryCard(
                              cashCut: viewModel.cashCut,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
