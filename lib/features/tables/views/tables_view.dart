import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/business_config.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/layouts/pos_shell.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/tables_view_model.dart';
import '../widgets/table_card.dart';
import '../widgets/table_status_legend.dart';

class TablesView extends StatefulWidget {
  const TablesView({super.key});

  @override
  State<TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<TablesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TablesViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TablesViewModel>(
      builder: (context, viewModel, child) {
        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: PosShell(
            title: BusinessConfig.current.footerText,
            subtitle: 'Mesas del turno',
            trailing: Builder(
              builder: (context) {
                final responsive = AppResponsive.of(context);
                return SizedBox(
                  height: responsive.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: viewModel.load,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: responsive.iconSize,
                    ),
                    label: Text(
                      'Actualizar',
                      style: TextStyle(fontSize: responsive.bodyFontSize),
                    ),
                  ),
                );
              },
            ),
            child: viewModel.errorMessage != null
                ? ErrorState(
                    message: viewModel.errorMessage!,
                    onRetry: viewModel.load,
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

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TableStatusLegend(responsive: responsive),
                          SizedBox(height: responsive.sectionGap),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: responsive.buttonHeight,
                              child: FilledButton.icon(
                                onPressed: viewModel.tables.isEmpty
                                    ? null
                                    : () async {
                                        final freeTable = viewModel.tables
                                            .firstWhere((t) => t.isFree);
                                        await viewModel.ensureOrderForTable(
                                          freeTable,
                                        );
                                        if (context.mounted) {
                                          Navigator.pushNamed(
                                            context,
                                            RouteNames.order,
                                            arguments: freeTable,
                                          );
                                        }
                                      },
                                icon: Icon(
                                  Icons.add_box_rounded,
                                  size: responsive.iconSize,
                                ),
                                label: Text(
                                  'Nueva orden / Asignar mesa',
                                  style: TextStyle(
                                    fontSize: responsive.bodyFontSize,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.sectionGap),
                          Expanded(
                            child: GridView.builder(
                              itemCount: viewModel.tables.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: responsive.tableGridColumns,
                                    crossAxisSpacing: responsive.spacingMd,
                                    mainAxisSpacing: responsive.spacingMd,
                                    mainAxisExtent: responsive.tableCardHeight,
                                    childAspectRatio:
                                        responsive.tableCardAspectRatio,
                                  ),
                              itemBuilder: (context, index) {
                                final table = viewModel.tables[index];
                                return TableCard(
                                  table: table,
                                  responsive: responsive,
                                  onTap: () async {
                                    await viewModel.ensureOrderForTable(table);
                                    if (context.mounted) {
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.order,
                                        arguments: table,
                                      );
                                    }
                                  },
                                );
                              },
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
