import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class MoreBottomSheet extends StatelessWidget {
  const MoreBottomSheet({
    super.key,
    required this.userName,
    required this.roleName,
    this.onPayments,
    this.onCashCut,
    this.onTodaySales,
    this.onProfile,
    this.onSync,
    this.onSettings,
    this.onSupport,
    this.onLogout,
  });

  final String userName;
  final String roleName;
  final VoidCallback? onPayments;
  final VoidCallback? onCashCut;
  final VoidCallback? onTodaySales;
  final VoidCallback? onProfile;
  final VoidCallback? onSync;
  final VoidCallback? onSettings;
  final VoidCallback? onSupport;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final trimmedName = userName.trim();
    final initial = trimmedName.isNotEmpty
        ? trimmedName.characters.first.toUpperCase()
        : '?';

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trimmedName.isEmpty ? 'Usuario' : trimmedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roleName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (onPayments != null)
                      _MoreActionTile(
                        icon: Icons.point_of_sale_rounded,
                        label: 'Caja',
                        onTap: onPayments,
                      ),
                    if (onCashCut != null)
                      _MoreActionTile(
                        icon: Icons.assessment_rounded,
                        label: 'Corte del dia',
                        onTap: onCashCut,
                      ),
                    if (onTodaySales != null)
                      _MoreActionTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Ventas del dia',
                        onTap: onTodaySales,
                      ),
                    _MoreActionTile(
                      icon: Icons.person_rounded,
                      label: 'Perfil',
                      onTap: onProfile,
                    ),
                    _MoreActionTile(
                      icon: Icons.sync_rounded,
                      label: 'Sincronización',
                      onTap: onSync,
                    ),
                    _MoreActionTile(
                      icon: Icons.settings_rounded,
                      label: 'Configuración',
                      onTap: onSettings,
                    ),
                    _MoreActionTile(
                      icon: Icons.support_agent_rounded,
                      label: 'Soporte',
                      onTap: onSupport,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: _MoreActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  destructive: true,
                  onTap: onLogout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreActionTile extends StatelessWidget {
  const _MoreActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: destructive
                      ? AppColors.danger.withValues(alpha: 0.08)
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: destructive ? AppColors.danger : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
