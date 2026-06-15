import 'package:flutter/material.dart';

class PaymentMethodButton extends StatelessWidget {
  const PaymentMethodButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        backgroundColor: selected ? Theme.of(context).colorScheme.primary : null,
        foregroundColor: selected ? Colors.white : null,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
