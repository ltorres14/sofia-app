import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/business_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';
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

    // limpiar círculos SIEMPRE después de intentar login
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
    final responsive = ResponsiveHelper(context);
    final screenWidth = responsive.width;
    final screenHeight = responsive.height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final horizontalPadding = screenWidth * 0.06;
    final logoBoxSize = screenWidth * 0.18;
    final logoIconSize = logoBoxSize * 0.42;

    final topSpace = screenHeight * 0.035;
    final headerGap = screenHeight * 0.015;
    final cardTopGap = screenHeight * 0.025;
    final footerGap = screenHeight * 0.025;

    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topSpace,
          horizontalPadding,
          bottomInset + 18,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                screenHeight -
                MediaQuery.paddingOf(context).top -
                MediaQuery.paddingOf(context).bottom -
                topSpace,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LogoBox(size: logoBoxSize, iconSize: logoIconSize),

              SizedBox(height: headerGap),

              Text(
                BusinessConfig.current.businessName,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: const Color(0xFF171717),
                  fontSize: screenWidth * 0.070,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),

              SizedBox(height: screenHeight * 0.010),

              Text(
                'Sistema punto de venta',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: const Color(0xFF6E6E6E),
                  fontSize: screenWidth * 0.040,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: cardTopGap),

              _PinCard(
                viewModel: viewModel,
                pinController: pinController,
                pinFocusNode: pinFocusNode,
                onTapPin: onTapPin,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              SizedBox(height: footerGap),

              const _FooterBrand(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox({required this.size, required this.iconSize});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB98633).withOpacity(0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.storefront_rounded,
        color: const Color(0xFFC97800),
        size: iconSize,
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
    required this.screenWidth,
    required this.screenHeight,
  });

  final PinLoginViewModel viewModel;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final VoidCallback onTapPin;
  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    final cardPaddingHorizontal = screenWidth * 0.065;
    final cardPaddingVertical = screenHeight * 0.026;
    final dotSize = screenWidth * 0.092;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapPin,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: cardPaddingHorizontal,
          vertical: cardPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFC),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB98633).withOpacity(0.13),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LockBadge(),

            SizedBox(height: screenHeight * 0.018),

            Text(
              'Ingresa tu PIN',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(
                color: const Color(0xFF171717),
                fontSize: screenWidth * 0.064,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),

            SizedBox(height: screenHeight * 0.010),

            Text(
              'Acceso para personal autorizado',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: const Color(0xFF6E6E6E),
                fontSize: screenWidth * 0.036,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: screenHeight * 0.030),

            _PinDotsIndicator(
              length: AppConstants.pinLength,
              filled: viewModel.pin.length,
              dotSize: dotSize,
            ),

            SizedBox(height: screenHeight * 0.032),

            const _ShieldDivider(),

            SizedBox(height: screenHeight * 0.024),

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
              SizedBox(height: screenHeight * 0.020),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.w600,
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
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1DC),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        color: Color(0xFFD07A00),
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
            color: isFilled ? const Color(0xFFD78A22) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isFilled
                  ? const Color(0xFFD78A22)
                  : const Color(0xFFF0D4A5),
              width: 2.6,
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
        Expanded(child: Container(height: 1, color: const Color(0xFFF0E5D5))),
        Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF5ED),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFFE4CFAE),
            size: 22,
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFF0E5D5))),
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
        color: const Color(0xFFFAF4EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: Color(0xFFD3932B),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solo personal autorizado',
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mantén tu cuenta segura',
                  style: TextStyle(
                    color: Color(0xFF707070),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'by ',
            style: TextStyle(
              color: Color(0xFF7D7D7D),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: 'SOFÍA',
            style: TextStyle(
              color: Color(0xFFD07A00),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          TextSpan(
            text: ' Check',
            style: TextStyle(
              color: Color(0xFF7D7D7D),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
