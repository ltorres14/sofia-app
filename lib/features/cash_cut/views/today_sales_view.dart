import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cash_cut/today_sales.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/today_sales_view_model.dart';

class TodaySalesView extends StatefulWidget {
  const TodaySalesView({super.key});

  @override
  State<TodaySalesView> createState() => _TodaySalesViewState();
}

class _TodaySalesViewState extends State<TodaySalesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodaySalesViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodaySalesViewModel>(
      builder: (context, viewModel, child) {
        final report = viewModel.todaySales;

        if (viewModel.isLoading && report == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null && report == null) {
          return _TodaySalesErrorState(
            message: viewModel.errorMessage!,
            onRetry: viewModel.load,
          );
        }

        if (report == null) {
          return _TodaySalesErrorState(
            message: 'No fue posible cargar las ventas del dia.',
            onRetry: viewModel.load,
          );
        }

        final responsive = AppResponsive.of(context);
        final summary = report.summary;

        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: responsive.spacingLg),
            children: [
              if (viewModel.errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: responsive.spacingMd),
                  child: _InlineErrorCard(
                    message: viewModel.errorMessage!,
                    onRetry: viewModel.load,
                  ),
                ),
              _SectionCard(
                child: _HeroSummaryCard(
                  summary: summary,
                  isRefreshing: viewModel.isLoading,
                  onRefresh: viewModel.load,
                ),
              ),
              SizedBox(height: responsive.spacingMd),
              _SectionCard(
                title: 'Ventas por metodo',
                icon: Icons.account_balance_wallet_rounded,
                child: _StatsGrid(
                  items: [
                    _StatItem(
                      label: 'Efectivo',
                      value: CurrencyFormatter.format(summary.totalCash),
                    ),
                    _StatItem(
                      label: 'Tarjeta',
                      value: CurrencyFormatter.format(summary.totalCard),
                    ),
                    _StatItem(
                      label: 'Transferencia',
                      value: CurrencyFormatter.format(summary.totalTransfer),
                    ),
                    _StatItem(
                      label: 'Mixto',
                      value: CurrencyFormatter.format(summary.totalMixed),
                    ),
                    _StatItem(
                      label: 'Otros',
                      value: CurrencyFormatter.format(summary.totalOther),
                    ),
                    _StatItem(
                      label: 'Propinas',
                      value: CurrencyFormatter.format(summary.totalTips),
                    ),
                    _StatItem(
                      label: 'Gastos',
                      value: CurrencyFormatter.format(summary.totalExpenses),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacingMd),
              _SectionCard(
                title: 'Metricas',
                icon: Icons.analytics_rounded,
                child: _StatsGrid(
                  columnsPortrait: 2,
                  columnsLandscape: 4,
                  items: [
                    _StatItem(
                      label: 'Pagos',
                      value: summary.paymentsCount.toString(),
                    ),
                    _StatItem(
                      label: 'Ordenes',
                      value: summary.ordersCount.toString(),
                    ),
                    _StatItem(
                      label: 'Mesas',
                      value: summary.tablesCount.toString(),
                    ),
                    _StatItem(
                      label: 'Promedio por venta',
                      caption: 'por orden',
                      value: CurrencyFormatter.format(summary.averageTicket),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacingLg),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacingXs),
                child: Text(
                  'Detalle de ventas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: responsive.spacingSm),
              if (report.sales.isEmpty)
                const _EmptySalesCard()
              else
                ...report.sales.map(_SaleCard.new),
            ],
          ),
        );
      },
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.summary,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final TodaySalesSummary summary;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final refreshButtonSize = responsive.buttonHeight.clamp(44, 52).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Hoy',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: refreshButtonSize,
              height: refreshButtonSize,
              child: OutlinedButton(
                onPressed: isRefreshing ? null : onRefresh,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isRefreshing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacingLg),
        Text(
          CurrencyFormatter.format(summary.totalSold),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Total vendido hoy',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('dd/MM/yyyy').format(summary.businessDate),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title, this.icon});

  final String? title;
  final IconData? icon;
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
          if (title != null && icon != null) ...[
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
                    title!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.items,
    this.columnsPortrait = 2,
    this.columnsLandscape = 4,
  });

  final List<_StatItem> items;
  final int columnsPortrait;
  final int columnsLandscape;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final columns = responsive.isPortrait ? columnsPortrait : columnsLandscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.spacingSm;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _StatTile(item: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (item.caption != null) ...[
            const SizedBox(height: 4),
            Text(
              item.caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard(this.sale);

  final TodaySale sale;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final cashierName = sale.cashierName?.trim() ?? '';
    final subtitle = cashierName.isEmpty
        ? _formatTime(sale.paidAt)
        : '${_formatTime(sale.paidAt)} · $cashierName';
    final methodVisual = _paymentMethodVisual(sale.paymentMethod);

    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacingSm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sale.displayTableName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(sale.total),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' · ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(methodVisual.icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    methodVisual.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    return DateFormat('h:mm a').format(value.toLocal()).toUpperCase();
  }

  _MethodVisual _paymentMethodVisual(String method) {
    switch (method.trim().toLowerCase()) {
      case 'cash':
        return const _MethodVisual(
          label: 'Efectivo',
          icon: Icons.payments_rounded,
        );
      case 'card':
        return const _MethodVisual(
          label: 'Tarjeta',
          icon: Icons.credit_card_rounded,
        );
      case 'transfer':
        return const _MethodVisual(
          label: 'Transferencia',
          icon: Icons.account_balance_rounded,
        );
      case 'mixed':
        return const _MethodVisual(
          label: 'Mixto',
          icon: Icons.account_balance_wallet_rounded,
        );
      case 'other':
      default:
        return const _MethodVisual(
          label: 'Otro',
          icon: Icons.more_horiz_rounded,
        );
    }
  }
}

class _MethodVisual {
  const _MethodVisual({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _EmptySalesCard extends StatelessWidget {
  const _EmptySalesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aun no hay ventas cobradas hoy.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySalesErrorState extends StatelessWidget {
  const _TodaySalesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
