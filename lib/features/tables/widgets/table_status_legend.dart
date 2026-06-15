import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';

class TableStatusLegend extends StatelessWidget {
  const TableStatusLegend({super.key, required this.responsive});

  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: responsive.spacingSm,
      runSpacing: responsive.spacingSm,
      children: [
        _LegendChip(
          label: 'Libre',
          color: Colors.green,
          responsive: responsive,
        ),
        _LegendChip(
          label: 'Con orden',
          color: Colors.orange,
          responsive: responsive,
        ),
        _LegendChip(
          label: 'Esperando pago',
          color: Colors.red,
          responsive: responsive,
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    required this.responsive,
  });

  final String label;
  final Color color;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacingSm,
        vertical: responsive.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: responsive.captionFontSize, color: color),
          SizedBox(width: responsive.spacingXs),
          Text(label, style: TextStyle(fontSize: responsive.captionFontSize)),
        ],
      ),
    );
  }
}
