import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order.dart';
import 'order_item_row.dart';

class CurrentOrderPanel extends StatelessWidget {
  const CurrentOrderPanel({
    super.key,
    required this.order,
    required this.onSendToKitchen,
    required this.sending,
  });

  final Order? order;
  final Future<void> Function() onSendToKitchen;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: order == null
            ? const Center(child: Text('No hay orden abierta para esta mesa.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orden actual', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: order!.items.map((item) => OrderItemRow(item: item)).toList(),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total'),
                      Text(
                        CurrencyFormatter.format(order!.total),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: sending ? null : () => onSendToKitchen(),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Enviar a Cocina'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
