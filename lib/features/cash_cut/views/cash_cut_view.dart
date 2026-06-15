import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/layouts/pos_shell.dart';
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
          child: PosShell(
            title: 'Corte del día',
            subtitle: 'Resumen de caja',
            child: viewModel.errorMessage != null
                ? ErrorState(message: viewModel.errorMessage!, onRetry: viewModel.load)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: CashCutSummaryCard(cashCut: viewModel.cashCut),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
