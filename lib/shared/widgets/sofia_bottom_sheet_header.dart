import 'package:flutter/material.dart';

import '../../core/responsive/app_responsive.dart';
import '../../core/theme/app_colors.dart';

class SofiaBottomSheetHeader extends StatelessWidget {
  const SofiaBottomSheetHeader({
    super.key,
    required this.title,
    this.showHandle = true,
    this.onClose,
    this.titleMaxLines = 2,
  });

  final String title;
  final bool showHandle;
  final VoidCallback? onClose;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final resolvedOnClose = onClose ?? () => Navigator.of(context).maybePop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHandle)
          Padding(
            padding: EdgeInsets.only(bottom: responsive.spacingMd),
            child: Center(
              child: Container(
                width: responsive.isPortrait ? 44 : 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: responsive.spacingXs),
                child: Text(
                  title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(width: responsive.spacingSm),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: resolvedOnClose,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  width: responsive.buttonHeight.clamp(40.0, 44.0).toDouble(),
                  height: responsive.buttonHeight.clamp(40.0, 44.0).toDouble(),
                  decoration: BoxDecoration(
                    color: AppColors.softBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
