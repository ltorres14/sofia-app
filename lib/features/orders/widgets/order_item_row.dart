import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/orders/order_item.dart';

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(child: Text('${item.quantity}')),
          const SizedBox(width: 12),
          Expanded(child: Text(item.productName)),
          Text(CurrencyFormatter.format(item.total)),
        ],
      ),
    );
  }
}
