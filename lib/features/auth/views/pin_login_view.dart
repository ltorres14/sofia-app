import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/business_config.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/pin_login_view_model.dart';
import '../widgets/pin_keypad.dart';
import '../widgets/role_hint_card.dart';

class PinLoginView extends StatefulWidget {
  const PinLoginView({super.key});

  @override
  State<PinLoginView> createState() => _PinLoginViewState();
}

class _PinLoginViewState extends State<PinLoginView> {
  bool _autoSubmitting = false;

  Future<void> _submitIfReady(PinLoginViewModel viewModel) async {
    if (_autoSubmitting || !viewModel.consumeAutoSubmit()) return;

    _autoSubmitting = true;
    final route = await viewModel.login();
    _autoSubmitting = false;

    if (route != null && mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PinLoginViewModel>(
      builder: (context, viewModel, child) {
        final responsive = AppResponsive.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _submitIfReady(viewModel);
          }
        });

        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(BusinessConfig.current.loginBackgroundAssetPath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    AppColors.primary.withValues(alpha: 0.82),
                    BlendMode.srcATop,
                  ),
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useVerticalLayout =
                        responsive.isPortrait || constraints.maxWidth < 900;
                    final outerPadding = EdgeInsets.symmetric(
                      horizontal: responsive.horizontalPadding,
                      vertical: responsive.verticalPadding,
                    );

                    return SingleChildScrollView(
                      padding: outerPadding,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: useVerticalLayout ? responsive.cardWidth : 1180,
                          ),
                          child: useVerticalLayout
                              ? _PinCard(
                                  viewModel: viewModel,
                                  responsive: responsive,
                                  compact: true,
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _BrandingSection(
                                        compact: false,
                                        responsive: responsive,
                                      ),
                                    ),
                                    SizedBox(width: responsive.spacingXl),
                                    SizedBox(
                                      width: responsive.cardWidth,
                                      child: _PinCard(
                                        viewModel: viewModel,
                                        responsive: responsive,
                                        compact: false,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandingSection extends StatelessWidget {
  const _BrandingSection({
    required this.compact,
    required this.responsive,
  });

  final bool compact;
  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? responsive.spacingLg : responsive.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: compact ? 36 : 46,
            backgroundImage: AssetImage(BusinessConfig.current.logoAssetPath),
          ),
          SizedBox(height: responsive.spacingMd),
          Text(
            BusinessConfig.current.businessName,
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: (compact ? AppTextStyles.sectionTitle : AppTextStyles.title).copyWith(
              color: Colors.white,
              fontSize: compact
                  ? responsive.titleFontSize.clamp(24, 30)
                  : responsive.titleFontSize,
            ),
          ),
          SizedBox(height: responsive.spacingXs),
          Text(
            BusinessConfig.current.businessSubtitle,
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: AppTextStyles.subtitle.copyWith(
              color: Colors.white70,
              fontSize: responsive.bodyFontSize,
            ),
          ),
          SizedBox(height: responsive.spacingLg),
          const RoleHintCard(
            title: 'Mesero',
            pin: '1111',
            icon: Icons.room_service_rounded,
            color: Colors.white,
          ),
          SizedBox(height: responsive.spacingSm),
          const RoleHintCard(
            title: 'Cocina',
            pin: '2222',
            icon: Icons.soup_kitchen_rounded,
            color: Colors.white,
          ),
          SizedBox(height: responsive.spacingSm),
          const RoleHintCard(
            title: 'Caja / Admin',
            pin: '3333',
            icon: Icons.point_of_sale_rounded,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard({
    required this.viewModel,
    required this.responsive,
    required this.compact,
  });

  final PinLoginViewModel viewModel;
  final AppResponsive responsive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? responsive.spacingMd : responsive.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu PIN',
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: compact
                    ? responsive.titleFontSize.clamp(22, 28)
                    : responsive.titleFontSize.clamp(24, 30),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: compact ? responsive.spacingSm : responsive.spacingXs),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: responsive.spacingSm,
              runSpacing: responsive.spacingXs,
              children: List.generate(
                4,
                (index) => Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: index < viewModel.pin.length
                        ? AppColors.accent
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (viewModel.errorMessage != null) ...[
              SizedBox(height: compact ? responsive.spacingXs : responsive.spacingSm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacingSm,
                  vertical: responsive.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: compact
                        ? (responsive.bodyFontSize - 1).clamp(13, 16)
                        : responsive.bodyFontSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (viewModel.isLoading) ...[
              SizedBox(height: responsive.spacingSm),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.accent,
                ),
              ),
            ],
            SizedBox(height: compact ? responsive.spacingMd : responsive.spacingLg),
            PinKeypad(
              onDigit: viewModel.appendDigit,
              onBackspace: viewModel.backspace,
              onClear: viewModel.clear,
              enabled: !viewModel.isLoading,
            ),
            if (!compact) ...[
              SizedBox(height: responsive.spacingMd),
              Text(
                BusinessConfig.current.footerText,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
