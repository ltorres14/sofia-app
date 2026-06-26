import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/cash_cut_view_model.dart';
import '../widgets/cash_cut_summary_card.dart';

class CashCutView extends StatefulWidget {
  const CashCutView({super.key});

  @override
  State<CashCutView> createState() => _CashCutViewState();
}

class _CashCutViewState extends State<CashCutView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashCutViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashCutViewModel>(
      builder: (context, viewModel, child) {
        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: viewModel.errorMessage != null
              ? ErrorState(
                  message: viewModel.errorMessage!,
                  onRetry: viewModel.load,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: CashCutSummaryCard(
                        cashCut: viewModel.cashCut,
                        isClosing: viewModel.isClosing,
                        closeEnabled: viewModel.canCloseCashCut,
                        onCloseCashCut: () => _handleCloseCashCut(viewModel),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _handleCloseCashCut(CashCutViewModel viewModel) async {
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
        : (viewModel.actionErrorMessage ??
              'No se pudo cerrar el corte del dia.');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    viewModel.clearActionStatus();
  }
}
