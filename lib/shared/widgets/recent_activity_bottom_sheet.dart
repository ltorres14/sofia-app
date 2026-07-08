import 'package:flutter/material.dart';

import '../../core/responsive/app_responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/activity/recent_activity_item.dart';
import 'recent_activity_card.dart';
import 'sofia_bottom_sheet_header.dart';

class RecentActivityHistoryButton extends StatelessWidget {
  const RecentActivityHistoryButton({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Tooltip(
      message: 'Ver historial',
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.border),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacingMd,
            vertical: responsive.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : const Icon(Icons.history_rounded, size: 18),
        label: const Text('Historial'),
      ),
    );
  }
}

class RecentActivityBottomSheet extends StatelessWidget {
  const RecentActivityBottomSheet({
    super.key,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.emptyMessage,
    this.title = 'Historial reciente',
  });

  final List<RecentActivityItem> items;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final String title;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.6,
        maxHeight:
            MediaQuery.of(context).size.height *
            (responsive.isPortrait ? 0.78 : 0.86),
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.spacingMd,
            responsive.spacingMd,
            responsive.spacingMd,
            responsive.bottomSheetContentPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SofiaBottomSheetHeader(title: title, showHandle: true),
              SizedBox(height: responsive.spacingSm),
              if (errorMessage != null && items.isNotEmpty) ...[
                _RecentActivityHint(message: errorMessage!),
                SizedBox(height: responsive.spacingSm),
              ],
              Expanded(
                child: _RecentActivityBottomSheetBody(
                  items: items,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  emptyMessage: emptyMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityBottomSheetBody extends StatelessWidget {
  const _RecentActivityBottomSheetBody({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.emptyMessage,
  });

  final List<RecentActivityItem> items;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    if (isLoading && items.isEmpty) {
      return const _RecentActivityState(
        icon: Icons.sync_rounded,
        message: 'Cargando movimientos recientes...',
      );
    }

    if (items.isEmpty && errorMessage != null) {
      return _RecentActivityState(
        icon: Icons.wifi_off_rounded,
        message: errorMessage!,
      );
    }

    if (items.isEmpty) {
      return _RecentActivityState(
        icon: Icons.history_rounded,
        message: emptyMessage,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: responsive.spacingXs),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: responsive.spacingMd),
      itemBuilder: (context, index) {
        return Align(
          alignment: Alignment.topCenter,
          child: RecentActivityCard(item: items[index]),
        );
      },
    );
  }
}

class _RecentActivityHint extends StatelessWidget {
  const _RecentActivityHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.16)),
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecentActivityState extends StatelessWidget {
  const _RecentActivityState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
