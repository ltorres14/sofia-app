import 'package:flutter/material.dart';

import '../../../core/utils/date_time_formatter.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';

class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    super.key,
    required this.ticket,
    required this.onAdvanceStatus,
  });

  final KitchenTicket ticket;
  final VoidCallback onAdvanceStatus;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (ticket.status) {
      1 => 'Pendiente',
      2 => 'Preparando',
      3 => 'Listo',
      _ => 'Cancelado',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(ticket.tableName, style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                Chip(label: Text(statusText)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Orden #${ticket.orderId} · ${DateTimeFormatter.shortTime(ticket.createdAt)}'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: ticket.items
                    .map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${item.quantity} x ${item.productName}'),
                          subtitle: item.notes == null ? null : Text(item.notes!),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ticket.status >= 3 ? null : onAdvanceStatus,
                icon: const Icon(Icons.local_fire_department_rounded),
                label: Text(ticket.status == 1 ? 'Marcar preparando' : 'Marcar listo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
