import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/business_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/responsive/app_responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../viewmodels/pin_login_view_model.dart';

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
    if (_autoSubmitting || !viewModel.consumeAutoSubmit()) {
      return;
    }

    _autoSubmitting = true;

    final route = await viewModel.login();

    viewModel.clear();

    _autoSubmitting = false;

    if (route != null && mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _openKeyboard() {
    _pinFocusNode.unfocus();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_pinFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PinLoginViewModel>(
      builder: (context, viewModel, child) {
        if (_pinController.text != viewModel.pin) {
          _pinController.value = TextEditingValue(
            text: viewModel.pin,
            selection: TextSelection.collapsed(offset: viewModel.pin.length),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _submitIfReady(viewModel);
        });

        return LoadingOverlay(
          loading: viewModel.isLoading,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: AppColors.appBackground,
            body: _PinLoginBody(
              viewModel: viewModel,
              pinController: _pinController,
              pinFocusNode: _pinFocusNode,
              onTapPin: _openKeyboard,
            ),
          ),
        );
      },
    );
  }
}

class _PinLoginBody extends StatelessWidget {
  const _PinLoginBody({
    required this.viewModel,
    required this.pinController,
    required this.pinFocusNode,
    required this.onTapPin,
  });

  final PinLoginViewModel viewModel;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final VoidCallback onTapPin;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          responsive.loginHorizontalPadding,
          responsive.loginTopSpacing,
          responsive.loginHorizontalPadding,
          responsive.viewInsetBottom + responsive.spacingMd,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (responsive.keyboardAwareAvailableHeight -
                    responsive.loginTopSpacing)
                .clamp(0.0, double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BusinessLogo(size: responsive.loginLogoSize),
              SizedBox(height: responsive.loginHeaderGap),
              Text(
                BusinessConfig.current.businessName,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: responsive.loginBusinessTitleFontSize,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              SizedBox(height: responsive.loginCardInnerGapXs),
              Text(
                'Sistema punto de venta',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: responsive.loginSupportFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: responsive.loginCardTopGap),
              _PinCard(
                viewModel: viewModel,
                pinController: pinController,
                pinFocusNode: pinFocusNode,
                onTapPin: onTapPin,
              ),
              SizedBox(height: responsive.loginFooterGap),
              const _FooterBrand(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessLogo extends StatelessWidget {
  const _BusinessLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        BusinessConfig.current.logoAssetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.storefront_rounded,
            color: AppColors.primary,
            size: size * 0.42,
          );
        },
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard({
    required this.viewModel,
    required this.pinController,
    required this.pinFocusNode,
    required this.onTapPin,
  });

  final PinLoginViewModel viewModel;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final VoidCallback onTapPin;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapPin,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.loginCardHorizontalPadding,
          vertical: responsive.loginCardVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LockBadge(),
            SizedBox(height: responsive.loginCardInnerGapSm),
            Text(
              'Ingresa tu PIN',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontSize: responsive.loginTitleFontSize,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            SizedBox(height: responsive.loginCardInnerGapXs),
            Text(
              'Acceso para personal autorizado',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.textSecondary,
                fontSize: responsive.loginSubtitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: responsive.loginCardInnerGapLg),
            _PinDotsIndicator(
              length: AppConstants.pinLength,
              filled: viewModel.pin.length,
              dotSize: responsive.loginPinDotSize,
            ),
            SizedBox(height: responsive.loginCardInnerGapLg),
            const _ShieldDivider(),
            SizedBox(height: responsive.loginCardInnerGapMd),
            const _AuthorizedInfoBox(),
            SizedBox(
              height: 1,
              width: double.infinity,
              child: _NativePinField(
                controller: pinController,
                focusNode: pinFocusNode,
                onChanged: viewModel.updatePin,
              ),
            ),
            if (viewModel.errorMessage != null) ...[
              SizedBox(height: responsive.loginCardInnerGapMd),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: responsive.loginSubtitleFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock_outline_rounded,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }
}

class _PinDotsIndicator extends StatelessWidget {
  const _PinDotsIndicator({
    required this.length,
    required this.filled,
    required this.dotSize,
  });

  final int length;
  final int filled;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (index) {
        final isFilled = index < filled;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isFilled ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isFilled
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.22),
              width: 2.5,
            ),
          ),
        );
      }),
    );
  }
}

class _ShieldDivider extends StatelessWidget {
  const _ShieldDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

class _AuthorizedInfoBox extends StatelessWidget {
  const _AuthorizedInfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_2_outlined,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solo personal autorizado',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Meseros • Cocina • Caja',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
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

class _NativePinField extends StatelessWidget {
  const _NativePinField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.01,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        readOnly: false,
        showCursor: false,
        enableInteractiveSelection: false,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: AppConstants.pinLength,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    if (!BusinessConfig.current.showSofiaBranding) {
      return const SizedBox.shrink();
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'by ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: 'SOFÍA',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          TextSpan(
            text: ' Check',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
