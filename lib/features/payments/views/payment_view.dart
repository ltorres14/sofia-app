import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/payments/payment_method.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../cash_cut/widgets/cash_cut_summary_card.dart';
import '../viewmodels/payment_view_model.dart';
import '../widgets/payment_method_button.dart';
import '../widgets/payment_summary_card.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key, this.initialTableId});

  final int? initialTableId;

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final _tableController = TextEditingController();
  final _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTableId != null && widget.initialTableId! > 0) {
      _tableController.text = widget.initialTableId!.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewModel>().load(
        initialTableId: widget.initialTableId,
      );
    });
  }

  @override
  void dispose() {
    _tableController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentViewModel>(
      builder: (context, viewModel, child) {
        _syncControllers(viewModel);
        final responsive = AppResponsive.of(context);

        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: responsive.isPortrait
              ? _buildMobileLayout(context, viewModel, responsive)
              : _buildWideLayout(context, viewModel, responsive),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    PaymentViewModel viewModel,
    AppResponsive responsive,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: responsive.spacingLg),
      children: [
        _buildSearchCard(context, viewModel),
        if (viewModel.errorMessage != null || viewModel.successMessage != null)
          Padding(
            padding: EdgeInsets.only(top: responsive.spacingMd),
            child: _FeedbackBanner(
              errorMessage: viewModel.errorMessage,
              successMessage: viewModel.successMessage,
              onDismiss: viewModel.clearStatus,
            ),
          ),
        SizedBox(height: responsive.spacingMd),
        PaymentSummaryCard(order: viewModel.activeOrder),
        SizedBox(height: responsive.spacingMd),
        _buildPaymentCard(context, viewModel),
        SizedBox(height: responsive.spacingMd),
        CashCutSummaryCard(
          cashCut: viewModel.cashCut,
          isClosing: viewModel.isClosingCashCut,
          closeEnabled: viewModel.canCloseCashCut,
          onCloseCashCut: () => _handleCloseCashCut(viewModel),
        ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    PaymentViewModel viewModel,
    AppResponsive responsive,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: responsive.spacingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              children: [
                _buildSearchCard(context, viewModel),
                if (viewModel.errorMessage != null ||
                    viewModel.successMessage != null) ...[
                  SizedBox(height: responsive.spacingMd),
                  _FeedbackBanner(
                    errorMessage: viewModel.errorMessage,
                    successMessage: viewModel.successMessage,
                    onDismiss: viewModel.clearStatus,
                  ),
                ],
                SizedBox(height: responsive.spacingMd),
                PaymentSummaryCard(order: viewModel.activeOrder),
              ],
            ),
          ),
          SizedBox(width: responsive.spacingMd),
          Expanded(
            flex: 9,
            child: Column(
              children: [
                _buildPaymentCard(context, viewModel),
                SizedBox(height: responsive.spacingMd),
                CashCutSummaryCard(
                  cashCut: viewModel.cashCut,
                  isClosing: viewModel.isClosingCashCut,
                  closeEnabled: viewModel.canCloseCashCut,
                  onCloseCashCut: () => _handleCloseCashCut(viewModel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context, PaymentViewModel viewModel) {
    return _SectionCard(
      title: 'Buscar orden por mesa',
      icon: Icons.search_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tableController,
            keyboardType: TextInputType.number,
            enabled: !viewModel.isPaying,
            decoration: const InputDecoration(
              labelText: 'Numero de mesa',
              hintText: 'Ejemplo: 12',
              prefixIcon: Icon(Icons.table_restaurant_rounded),
            ),
            onSubmitted: (_) => _handleLoadOrder(viewModel),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: viewModel.isPaying
                  ? null
                  : () => _handleLoadOrder(viewModel),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Cargar orden'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.todaySales),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Ver ventas del dia'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentViewModel viewModel) {
    final activeOrder = viewModel.activeOrder;
    final hasPayableOrder = viewModel.hasPayableOrder;

    return _SectionCard(
      title: 'Metodo de pago',
      icon: Icons.point_of_sale_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPayableOrder && activeOrder != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeOrder.tableName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Orden #${activeOrder.id}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.format(activeOrder.total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._buildMethodButtons(viewModel),
            const SizedBox(height: 16),
            TextField(
              controller: _commentsController,
              minLines: 2,
              maxLines: 4,
              enabled: !viewModel.isPaying,
              decoration: const InputDecoration(
                labelText: 'Comentarios del pago (opcional)',
                hintText: 'Referencia, observacion o detalle adicional',
                alignLabelWithHint: true,
              ),
              onChanged: viewModel.updateComments,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: viewModel.canConfirmPayment
                    ? viewModel.payCurrentOrder
                    : null,
                icon: viewModel.isPaying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  viewModel.isPaying
                      ? 'Procesando pago...'
                      : 'Confirmar pago ${CurrencyFormatter.format(activeOrder.total)}',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
          ] else
            Text(
              'Carga una mesa con una orden pendiente de cobro para habilitar el pago.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMethodButtons(PaymentViewModel viewModel) {
    return [
      for (
        var index = 0;
        index < viewModel.availableMethods.length;
        index++
      ) ...[
        PaymentMethodButton(
          label: _methodLabel(viewModel.availableMethods[index]),
          icon: _methodIcon(viewModel.availableMethods[index]),
          selected:
              viewModel.selectedMethod == viewModel.availableMethods[index],
          onTap: () =>
              viewModel.selectMethod(viewModel.availableMethods[index]),
        ),
        if (index < viewModel.availableMethods.length - 1)
          const SizedBox(height: 12),
      ],
    ];
  }

  void _handleLoadOrder(PaymentViewModel viewModel) {
    final tableId = int.tryParse(_tableController.text.trim());
    viewModel.loadOrderByTable(tableId ?? 0);
  }

  void _syncControllers(PaymentViewModel viewModel) {
    if (_commentsController.text == viewModel.comments) {
      return;
    }

    _commentsController.value = TextEditingValue(
      text: viewModel.comments,
      selection: TextSelection.collapsed(offset: viewModel.comments.length),
    );
  }

  Future<void> _handleCloseCashCut(PaymentViewModel viewModel) async {
    final responsive = AppResponsive.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final useVerticalActions = responsive.isPortrait;

        return AlertDialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive.productListCardRadius,
            ),
          ),
          title: Text(
            'Cerrar corte del dia',
            style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
              fontSize: responsive.orderTitleFontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Deseas cerrar el corte del dia? Despues de cerrar el corte no se podra volver a cerrar este mismo dia.',
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
              fontSize: responsive.orderBodyFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            responsive.spacingXl,
            0,
            responsive.spacingXl,
            responsive.spacingXl,
          ),
          actions: useVerticalActions
              ? [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: const Text(
                            'Cancelar',
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                        SizedBox(height: responsive.spacingSm),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cerrar corte',
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(120, 44),
                    ),
                    child: const Text('Cancelar', maxLines: 1, softWrap: false),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cerrar corte',
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await viewModel.closeCashCut();
    if (!mounted) return;

    final message = success
        ? (viewModel.successMessage ?? 'Corte del dia cerrado correctamente.')
        : (viewModel.errorMessage ?? 'No se pudo cerrar el corte del dia.');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _methodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.other:
        return 'Otro';
      case PaymentMethod.mixed:
        return 'Mixto';
    }
  }

  IconData _methodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.transfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.other:
        return Icons.more_horiz_rounded;
      case PaymentMethod.mixed:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.errorMessage,
    required this.successMessage,
    required this.onDismiss,
  });

  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    final backgroundColor = hasError
        ? AppColors.danger.withValues(alpha: 0.08)
        : AppColors.success.withValues(alpha: 0.10);
    final foregroundColor = hasError ? AppColors.danger : AppColors.success;
    final message = hasError
        ? (errorMessage?.trim() ?? '')
        : (successMessage?.trim() ?? 'Operacion completada.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: foregroundColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: foregroundColor),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
