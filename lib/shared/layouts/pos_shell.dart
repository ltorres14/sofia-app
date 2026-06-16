import 'package:flutter/material.dart';

import '../../core/config/business_config.dart';
import '../../core/responsive/app_responsive.dart';
import 'pos_header.dart';
import 'responsive_scaffold.dart';

class PosShell extends StatelessWidget {
  const PosShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final hideFooterOnMobilePortrait =
        responsive.isPortrait && responsive.screenWidth < 600;

    return ResponsiveScaffold(
      body: Padding(
        padding: responsive.contentPadding,
        child: Column(
          children: [
            PosHeader(
              title: BusinessConfig.current.businessName,
              subtitle: subtitle,
              trailing: trailing,
            ),
            SizedBox(height: responsive.sectionGap),
            Expanded(child: child),
            if (!hideFooterOnMobilePortrait) ...[
              SizedBox(height: responsive.spacingSm),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: responsive.captionFontSize,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
