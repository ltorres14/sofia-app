import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

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
    final backgroundColor = selected ? AppColors.primary : AppColors.white;
    final foregroundColor = selected ? AppColors.white : AppColors.textPrimary;
    final borderColor = selected ? AppColors.primary : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.16)
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
