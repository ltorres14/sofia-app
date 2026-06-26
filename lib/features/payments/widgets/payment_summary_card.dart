import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/orders/order_item.dart';
import '../../../data/models/orders/order_selection.dart';
import '../../../data/models/orders/order_selection_item.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({super.key, required this.order});

  final Order? order;

  @override
  Widget build(BuildContext context) {
    final currentOrder = order;
    final theme = Theme.of(context);

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
      child: currentOrder == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cobro actual',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Busca una mesa para ver la orden, sus selecciones y el total pendiente.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PaymentOrderHeader(order: currentOrder),
                const SizedBox(height: 16),
                if (currentOrder.selections.isNotEmpty)
                  ..._buildSelectionBreakdown(currentOrder.selections)
                else
                  ..._buildLegacyBreakdown(context, currentOrder.items),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total a pagar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(currentOrder.total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildSelectionBreakdown(List<OrderSelection> selections) {
    return [
      for (var index = 0; index < selections.length; index++) ...[
        _SelectionBreakdownCard(selection: selections[index]),
        if (index < selections.length - 1) const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _buildLegacyBreakdown(
    BuildContext context,
    List<OrderItem> items,
  ) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.softBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'La orden no tiene productos visibles.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              for (var index = 0; index < items.length; index++) ...[
                _LegacyItemRow(item: items[index]),
                if (index < items.length - 1) const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    ];
  }
}

class _PaymentOrderHeader extends StatelessWidget {
  const _PaymentOrderHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final hasSelections = order.selections.isNotEmpty;
    final detailLabel = hasSelections
        ? '${order.selections.length} ${order.selections.length == 1 ? 'seleccion' : 'selecciones'}'
        : '${order.items.length} ${order.items.length == 1 ? 'producto' : 'productos'}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.tableName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Orden #${order.id} - $detailLabel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Mesa ${order.tableId}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionBreakdownCard extends StatelessWidget {
  const _SelectionBreakdownCard({required this.selection});

  final OrderSelection selection;

  @override
  Widget build(BuildContext context) {
    final notes = selection.notes?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selection.label.isNotEmpty
                          ? selection.label
                          : 'Seleccion ${selection.sequenceNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.format(selection.total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selection.items.isEmpty)
            Text(
              'Sin items visibles en esta seleccion.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            for (var index = 0; index < selection.items.length; index++) ...[
              _SelectionItemRow(item: selection.items[index]),
              if (index < selection.items.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _SelectionItemRow extends StatelessWidget {
  const _SelectionItemRow({required this.item});

  final OrderSelectionItem item;

  @override
  Widget build(BuildContext context) {
    final notes = item.notes?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.quantity} x ${item.productName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.format(item.total),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegacyItemRow extends StatelessWidget {
  const _LegacyItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final notes = item.notes?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.quantity} x ${item.productName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CurrencyFormatter.format(item.total),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
