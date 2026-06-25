import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PosBottomNavItem {
  const PosBottomNavItem({
    required this.label,
    required this.icon,
    this.routeName,
    this.isMore = false,
  });

  final String label;
  final IconData icon;
  final String? routeName;
  final bool isMore;
}

class PosBottomNav extends StatelessWidget {
  const PosBottomNav({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.onTap,
  });

  final List<PosBottomNavItem> items;
  final String currentRoute;
  final ValueChanged<PosBottomNavItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 68,
          child: Row(
            children: items.map((item) {
              final isActive = !item.isMore && item.routeName == currentRoute;

              return Expanded(
                child: _NavItemButton(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(item),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final PosBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? AppColors.primary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: foreground,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: const TextScaler.linear(1),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        height: 1,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                        color: foreground,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
