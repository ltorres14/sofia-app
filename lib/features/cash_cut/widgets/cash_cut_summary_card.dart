import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cash_cut/cash_cut.dart';

class CashCutSummaryCard extends StatelessWidget {
  const CashCutSummaryCard({super.key, required this.cashCut});

  final CashCut? cashCut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: cashCut == null
            ? const Center(child: Text('Sin datos de corte por ahora.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen de corte', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _Row(label: 'Ventas del día', value: CurrencyFormatter.format(cashCut!.grandTotal)),
                  _Row(label: 'Efectivo', value: CurrencyFormatter.format(cashCut!.totalCash)),
                  _Row(label: 'Tarjeta', value: CurrencyFormatter.format(cashCut!.totalCard)),
                  _Row(label: 'Transferencia', value: CurrencyFormatter.format(cashCut!.totalTransfer)),
                  _Row(label: 'Propinas', value: CurrencyFormatter.format(cashCut!.tips)),
                  _Row(label: 'Gastos', value: CurrencyFormatter.format(cashCut!.expenses)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.lock_clock_rounded),
                      label: const Text('Cerrar Corte del Día'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
