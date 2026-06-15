import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/business_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/safe_app_image.dart';
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
  late final TextEditingController _pinController;
  late final FocusNode _pinFocusNode;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _pinFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

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
        final useNativePinField =
            responsive.isPortrait && !responsive.isTablet;

        if (_pinController.text != viewModel.pin) {
          _pinController.value = TextEditingValue(
            text: viewModel.pin,
            selection: TextSelection.collapsed(offset: viewModel.pin.length),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (useNativePinField &&
              !_pinFocusNode.hasFocus &&
              !viewModel.isLoading) {
            _pinFocusNode.requestFocus();
          }
          _submitIfReady(viewModel);
        });

        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: Scaffold(
            body: useNativePinField
                ? _MobilePortraitLogin(
                    responsive: responsive,
                    viewModel: viewModel,
                    pinController: _pinController,
                    pinFocusNode: _pinFocusNode,
                  )
                : _WideLoginLayout(
                    responsive: responsive,
                    viewModel: viewModel,
                  ),
          ),
        );
      },
    );
  }
}

class _MobilePortraitLogin extends StatelessWidget {
  const _MobilePortraitLogin({
    required this.responsive,
    required this.viewModel,
    required this.pinController,
    required this.pinFocusNode,
  });

  final AppResponsive responsive;
  final PinLoginViewModel viewModel;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final horizontalPadding = math.min(responsive.horizontalPadding, 24.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08233E), Color(0xFF061A2F)],
        ),
      ),
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            responsive.verticalPadding,
            horizontalPadding,
            responsive.verticalPadding + insets.bottom,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = math.max(
                constraints.maxHeight - insets.bottom,
                0,
              ).toDouble();

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MobileBrandHeader(responsive: responsive),
                      SizedBox(height: responsive.spacingXl),
                      _MobilePinCard(
                        responsive: responsive,
                        viewModel: viewModel,
                        pinController: pinController,
                        pinFocusNode: pinFocusNode,
                      ),
                      SizedBox(height: responsive.spacingLg),
                      _MobileFooter(responsive: responsive),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader({required this.responsive});

  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    final logoSize = (responsive.screenWidth * 0.21).clamp(72.0, 92.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SafeAppImage.asset(
            assetPath: BusinessConfig.current.logoAssetPath,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
            fallbackIcon: Icons.storefront_rounded,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            iconColor: Colors.white,
            iconSize: 28,
          ),
        ),
        SizedBox(height: responsive.spacingMd),
        Text(
          'La Casita del Marisco',
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: Colors.white,
            fontSize: responsive.titleFontSize.clamp(26, 30),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: responsive.spacingXs),
        Text(
          'Sistema punto de venta',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle.copyWith(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: responsive.bodyFontSize,
          ),
        ),
      ],
    );
  }
}

class _MobilePinCard extends StatelessWidget {
  const _MobilePinCard({
    required this.responsive,
    required this.viewModel,
    required this.pinController,
    required this.pinFocusNode,
  });

  final AppResponsive responsive;
  final PinLoginViewModel viewModel;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: pinFocusNode.requestFocus,
        child: Padding(
          padding: EdgeInsets.all(responsive.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa tu PIN',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: const Color(0xFF102A43),
                  fontSize: responsive.titleFontSize.clamp(26, 30),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: responsive.spacingSm),
              Text(
                'Acceso para personal autorizado',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: const Color(0xFF52606D),
                  fontSize: responsive.bodyFontSize,
                ),
              ),
              SizedBox(height: responsive.spacingXl),
              GestureDetector(
                onTap: pinFocusNode.requestFocus,
                child: _PinDotsIndicator(
                  responsive: responsive,
                  length: AppConstants.pinLength,
                  filled: viewModel.pin.length,
                ),
              ),
              SizedBox(height: responsive.spacingMd),
              _HiddenNativePinField(
                controller: pinController,
                focusNode: pinFocusNode,
                onChanged: viewModel.updatePin,
              ),
              if (viewModel.errorMessage != null) ...[
                SizedBox(height: responsive.spacingMd),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacingSm,
                    vertical: responsive.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: responsive.bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenNativePinField extends StatelessWidget {
  const _HiddenNativePinField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        showCursor: false,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: AppConstants.pinLength,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 1,
          color: Colors.transparent,
          height: 1,
        ),
        cursorColor: Colors.transparent,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PinDotsIndicator extends StatelessWidget {
  const _PinDotsIndicator({
    required this.responsive,
    required this.length,
    required this.filled,
  });

  final AppResponsive responsive;
  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final dotSize = (responsive.screenWidth * 0.15).clamp(56.0, 68.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (index) {
        final isFilled = index < filled;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isFilled ? const Color(0xFF102A43) : const Color(0xFFF5F7FA),
            shape: BoxShape.circle,
            border: Border.all(
              color: isFilled
                  ? const Color(0xFF102A43)
                  : const Color(0xFFD9E2EC),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

class _MobileFooter extends StatelessWidget {
  const _MobileFooter({required this.responsive});

  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return Text(
      'by SOFÍA Check',
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(
        color: Colors.white.withValues(alpha: 0.72),
        fontSize: responsive.bodyFontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _WideLoginLayout extends StatelessWidget {
  const _WideLoginLayout({
    required this.responsive,
    required this.viewModel,
  });

  final AppResponsive responsive;
  final PinLoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF061A2F)),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: responsive.verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _WideBrandingSection(responsive: responsive)),
                  SizedBox(width: responsive.spacingXl),
                  SizedBox(
                    width: responsive.cardWidth,
                    child: _WidePinCard(
                      responsive: responsive,
                      viewModel: viewModel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WideBrandingSection extends StatelessWidget {
  const _WideBrandingSection({required this.responsive});

  final AppResponsive responsive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SafeAppImage.asset(
            assetPath: BusinessConfig.current.logoAssetPath,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            fallbackIcon: Icons.storefront_rounded,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            iconColor: Colors.white,
            iconSize: 32,
          ),
        ),
        SizedBox(height: responsive.spacingLg),
        Text(
          BusinessConfig.current.businessName,
          style: AppTextStyles.title.copyWith(
            color: Colors.white,
            fontSize: responsive.titleFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: responsive.spacingXs),
        Text(
          'Sistema punto de venta',
          style: AppTextStyles.subtitle.copyWith(
            color: Colors.white.withValues(alpha: 0.76),
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
    );
  }
}

class _WidePinCard extends StatelessWidget {
  const _WidePinCard({
    required this.responsive,
    required this.viewModel,
  });

  final AppResponsive responsive;
  final PinLoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu PIN',
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: responsive.titleFontSize.clamp(24, 30),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacingSm),
            Text(
              'Acceso para personal autorizado',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.black54,
                fontSize: responsive.bodyFontSize,
              ),
            ),
            SizedBox(height: responsive.spacingLg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: responsive.spacingSm,
              children: List.generate(
                AppConstants.pinLength,
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
              SizedBox(height: responsive.spacingSm),
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
                    fontSize: responsive.bodyFontSize,
                  ),
                  textAlign: TextAlign.center,
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
            SizedBox(height: responsive.spacingLg),
            PinKeypad(
              onDigit: viewModel.appendDigit,
              onBackspace: viewModel.backspace,
              onClear: viewModel.clear,
              enabled: !viewModel.isLoading,
            ),
            SizedBox(height: responsive.spacingMd),
            Text(
              'by SOFÍA Check',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
