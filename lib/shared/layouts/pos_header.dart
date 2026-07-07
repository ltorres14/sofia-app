import 'package:flutter/material.dart';

import '../../core/config/business_config.dart';
import '../../core/responsive/app_responsive.dart';
import '../widgets/safe_app_image.dart';

class PosHeader extends StatelessWidget {
  const PosHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: responsive.spacingMd),
        ],
        SizedBox(
          width: responsive.isPortrait ? 48 : 56,
          height: responsive.isPortrait ? 48 : 56,
          child: ClipOval(
            child: SafeAppImage.asset(
              assetPath: BusinessConfig.current.logoAssetPath,
              fallbackIcon: Icons.storefront_rounded,
              iconSize: responsive.iconSize + 4,
            ),
          ),
        ),
        SizedBox(width: responsive.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: responsive.titleFontSize.clamp(22, 30).toDouble(),
                ),
              ),
              SizedBox(height: responsive.spacingXs / 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.bodyFontSize,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[trailing!],
      ],
    );
  }
}
