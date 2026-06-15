import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.total,
    required this.orderId,
  });

  final double total;
  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cobro actual', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(orderId == null ? 'Sin orden seleccionada' : 'Orden #$orderId'),
            const Spacer(),
            Text('Total a pagar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(total),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );
  }
}
