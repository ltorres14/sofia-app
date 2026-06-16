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
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, -4),
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
    final foreground =
        isActive ? AppColors.primaryAmberDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: isActive ? const Color(0xFFF6E9D3) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 22, color: foreground),
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