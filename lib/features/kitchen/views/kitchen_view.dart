import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/responsive/app_responsive.dart';
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
  Timer? _pollingTimer;
  String? _lastActionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KitchenViewModel>().load();
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route?.isCurrent == false) {
        return;
      }

      await context.read<KitchenViewModel>().load(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KitchenViewModel>(
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
                  onRetry: viewModel.load,
                )
              : viewModel.tickets.isEmpty
              ? const EmptyState(
                  message: 'No hay comandas pendientes en este momento.',
                  icon: Icons.check_circle_outline_rounded,
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

                    if (responsive.isPortrait || constraints.maxWidth < 900) {
                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          responsive.spacingMd,
                          responsive.spacingMd,
                          responsive.spacingMd,
                          responsive.spacingXl + 60,
                        ),
                        itemCount: viewModel.tickets.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: responsive.spacingMd),
                        itemBuilder: (context, index) {
                          final ticket = viewModel.tickets[index];
                          return KitchenTicketCard(
                            ticket: ticket,
                            onAdvanceStatus: () =>
                                viewModel.advanceStatus(ticket),
                            isLegacyActionLoading: viewModel
                                .isLegacyActionLoading(ticket.id),
                            onAdvanceSelectionStatus: (selection) => viewModel
                                .advanceSelectionStatus(ticket, selection),
                            isSelectionLoading: (selection) =>
                                viewModel.isSelectionActionLoading(
                                  ticket.id,
                                  selection.orderSelectionId,
                                ),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        responsive.spacingMd,
                        responsive.spacingMd,
                        responsive.spacingMd,
                        responsive.spacingXl + 60,
                      ),
                      itemCount: viewModel.tickets.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth >= 1400 ? 3 : 2,
                        crossAxisSpacing: responsive.spacingMd,
                        mainAxisSpacing: responsive.spacingMd,
                        mainAxisExtent: 520,
                      ),
                      itemBuilder: (context, index) {
                        final ticket = viewModel.tickets[index];
                        return KitchenTicketCard(
                          ticket: ticket,
                          onAdvanceStatus: () =>
                              viewModel.advanceStatus(ticket),
                          isLegacyActionLoading: viewModel
                              .isLegacyActionLoading(ticket.id),
                          onAdvanceSelectionStatus: (selection) => viewModel
                              .advanceSelectionStatus(ticket, selection),
                          isSelectionLoading: (selection) =>
                              viewModel.isSelectionActionLoading(
                                ticket.id,
                                selection.orderSelectionId,
                              ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
