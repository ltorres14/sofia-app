import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/config/business_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/safe_app_image.dart';
import '../viewmodels/pin_login_view_model.dart';
import '../widgets/pin_keypad.dart';

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
        final size = MediaQuery.sizeOf(context);
        final isTablet = size.shortestSide >= 600;
        final useNativeKeyboard = !isTablet;
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
            backgroundColor: const Color(0xFF08233E),
            body: _PinLoginBody(
              viewModel: viewModel,
              pinController: _pinController,
              pinFocusNode: _pinFocusNode,
              useNativeKeyboard: useNativeKeyboard,
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
    required this.useNativeKeyboard,
  });
  final PinLoginViewModel viewModel;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final bool useNativeKeyboard;
  double _clamp(num value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = size.shortestSide >= 600;
    final horizontalPadding = _clamp(screenWidth * 0.06, 18, 48);
    final topPadding = _clamp(screenHeight * 0.045, 24, 52);
    final logoSize = _clamp(screenWidth * (isTablet ? 0.14 : 0.22), 78, 130);
    final maxContentWidth = isTablet ? 460.0 : double.infinity;
    final titleSize = _clamp(screenWidth * 0.07, 24, 34);
    final subtitleSize = _clamp(screenWidth * 0.036, 13, 17);
    final cardTitleSize = _clamp(screenWidth * 0.058, 22, 30);
    final dotSize = _clamp(screenWidth * 0.115, 42, 56);
    final gapSmall = _clamp(screenHeight * 0.012, 8, 14);
    final gapMedium = _clamp(screenHeight * 0.024, 16, 28);
    final gapLarge = _clamp(screenHeight * 0.04, 24, 44);
    final footerGap = _clamp(screenHeight * 0.08, 36, 80);
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          math.max(20, bottomInset + 20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                screenHeight -
                MediaQuery.paddingOf(context).top -
                MediaQuery.paddingOf(context).bottom -
                topPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SafeAppImage.asset(
                    assetPath: BusinessConfig.current.logoAssetPath,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    fallbackIcon: Icons.storefront_rounded,
                    backgroundColor: Colors.white,
                    iconColor: const Color(0xFF08233E),
                    iconSize: logoSize * 0.42,
                  ),
                  SizedBox(height: gapMedium),
                  Text(
                    BusinessConfig.current.businessName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: gapSmall),
                  Text(
                    'Sistema punto de venta',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: gapLarge),
                  _PinCard(
                    viewModel: viewModel,
                    pinController: pinController,
                    pinFocusNode: pinFocusNode,
                    useNativeKeyboard: useNativeKeyboard,
                    dotSize: dotSize,
                    cardTitleSize: cardTitleSize,
                    subtitleSize: subtitleSize,
                    gapSmall: gapSmall,
                    gapMedium: gapMedium,
                    onTap: () {
                      pinFocusNode.unfocus();
                      Future.delayed(const Duration(milliseconds: 50), () {
                        FocusScope.of(context).requestFocus(pinFocusNode);
                      });
                    },
                  ),
                  SizedBox(height: footerGap),
                  Text(
                    'by SOFÍA Check',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w500,
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

class _PinCard extends StatelessWidget {
  const _PinCard({
    required this.viewModel,
    required this.pinController,
    required this.pinFocusNode,
    required this.useNativeKeyboard,
    required this.dotSize,
    required this.cardTitleSize,
    required this.subtitleSize,
    required this.gapSmall,
    required this.gapMedium,
    required this.onTap,
  });
  final PinLoginViewModel viewModel;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final bool useNativeKeyboard;
  final double dotSize;
  final double cardTitleSize;
  final double subtitleSize;
  final double gapSmall;
  final double gapMedium;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Card(
        color: Colors.white,
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(gapMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa tu PIN',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: const Color(0xFF102A43),
                  fontSize: cardTitleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: gapSmall),
              Text(
                'Acceso para personal autorizado',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: const Color(0xFF52606D),
                  fontSize: subtitleSize,
                ),
              ),
              SizedBox(height: gapMedium),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: _PinDotsIndicator(
                  length: AppConstants.pinLength,
                  filled: viewModel.pin.length,
                  dotSize: dotSize,
                ),
              ),
              if (useNativeKeyboard)
                SizedBox(
                  height: 1,
                  width: double.infinity,
                  child: _NativePinField(
                    controller: pinController,
                    focusNode: pinFocusNode,
                    onChanged: viewModel.updatePin,
                  ),
                )
              else ...[
                SizedBox(height: gapMedium),
                PinKeypad(
                  onDigit: viewModel.appendDigit,
                  onBackspace: viewModel.backspace,
                  onClear: viewModel.clear,
                  enabled: !viewModel.isLoading,
                ),
              ],
              if (viewModel.errorMessage != null) ...[
                SizedBox(height: gapMedium),
                Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w600,
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
      child: SizedBox(
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          readOnly: false,
          showCursor: false,
          enableInteractiveSelection: false,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onTapAlwaysCalled: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          maxLength: AppConstants.pinLength,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            counterText: '',
          ),
        ),
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
              width: 1.4,
            ),
          ),
        );
      }),
    );
  }
}
