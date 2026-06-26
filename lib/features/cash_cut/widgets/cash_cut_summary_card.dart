import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cash_cut/cash_cut.dart';

class CashCutSummaryCard extends StatelessWidget {
  const CashCutSummaryCard({
    super.key,
    required this.cashCut,
    this.onCloseCashCut,
    this.isClosing = false,
    this.closeEnabled = true,
  });

  final CashCut? cashCut;
  final VoidCallback? onCloseCashCut;
  final bool isClosing;
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final isClosed = cashCut?.isClosed ?? false;

    return Card(
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(
          responsive.isPortrait ? AppSpacing.md : AppSpacing.lg,
        ),
        child: cashCut == null
            ? Text(
                'Sin datos de corte por ahora. Registra cobros para ver el resumen del dia.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen de corte', style: AppTextStyles.sectionTitle),
                  if (isClosed && cashCut!.closedAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        'Corte cerrado',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Cerrado: ${_formatClosedAt(cashCut!.closedAt!)}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _Row(
                    label: 'Ventas del dia',
                    value: CurrencyFormatter.format(cashCut!.grandTotal),
                  ),
                  _Row(
                    label: 'Efectivo',
                    value: CurrencyFormatter.format(cashCut!.totalCash),
                  ),
                  _Row(
                    label: 'Tarjeta',
                    value: CurrencyFormatter.format(cashCut!.totalCard),
                  ),
                  _Row(
                    label: 'Transferencia',
                    value: CurrencyFormatter.format(cashCut!.totalTransfer),
                  ),
                  if (cashCut!.totalMixed > 0)
                    _Row(
                      label: 'Mixto',
                      value: CurrencyFormatter.format(cashCut!.totalMixed),
                    ),
                  if (cashCut!.totalOther > 0)
                    _Row(
                      label: 'Otro',
                      value: CurrencyFormatter.format(cashCut!.totalOther),
                    ),
                  _Row(
                    label: 'Propinas',
                    value: CurrencyFormatter.format(cashCut!.tips),
                  ),
                  _Row(
                    label: 'Gastos',
                    value: CurrencyFormatter.format(cashCut!.expenses),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: closeEnabled && !isClosing && !isClosed
                          ? onCloseCashCut
                          : null,
                      icon: isClosing
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
                          : const Icon(Icons.lock_clock_rounded),
                      label: Text(
                        isClosing
                            ? 'Cerrando corte...'
                            : isClosed
                            ? 'Corte del dia cerrado'
                            : 'Cerrar Corte del Dia',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatClosedAt(DateTime value) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(value.toLocal());
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
