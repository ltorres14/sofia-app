import 'package:flutter/material.dart';

import '../../../core/responsive/app_responsive.dart';

class RoleHintCard extends StatelessWidget {
  const RoleHintCard({
    super.key,
    required this.title,
    required this.pin,
    required this.icon,
    required this.color,
  });

  final String title;
  final String pin;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      padding: EdgeInsets.all(responsive.spacingSm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: responsive.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: responsive.bodyFontSize,
                      ),
                ),
                Text(
                  'PIN $pin',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: responsive.bodyFontSize - 1,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
