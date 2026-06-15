import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/layouts/pos_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/kitchen_view_model.dart';
import '../widgets/kitchen_ticket_card.dart';

class KitchenView extends StatefulWidget {
  const KitchenView({super.key});

  @override
  State<KitchenView> createState() => _KitchenViewState();
}

class _KitchenViewState extends State<KitchenView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KitchenViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KitchenViewModel>(
      builder: (context, viewModel, child) {
        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: PosShell(
            title: 'SOFIA Check',
            subtitle: 'Comandas en cocina',
            trailing: FilledButton.icon(
              onPressed: viewModel.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualizar'),
            ),
            child: viewModel.errorMessage != null
                ? ErrorState(message: viewModel.errorMessage!, onRetry: viewModel.load)
                : viewModel.tickets.isEmpty
                    ? const EmptyState(
                        message: 'No hay comandas pendientes en este momento.',
                        icon: Icons.check_circle_outline_rounded,
                      )
                    : GridView.builder(
                        itemCount: viewModel.tickets.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                        itemBuilder: (context, index) {
                          final ticket = viewModel.tickets[index];
                          return KitchenTicketCard(
                            ticket: ticket,
                            onAdvanceStatus: () => viewModel.advanceStatus(ticket),
                          );
                        },
                      ),
          ),
        );
      },
    );
  }
}
