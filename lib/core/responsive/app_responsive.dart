import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._(this.context, {Size? layoutSize}) : _layoutSize = layoutSize;

  factory AppResponsive.of(BuildContext context, {Size? layoutSize}) =>
      AppResponsive._(context, layoutSize: layoutSize);

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static double percentWidth(BuildContext context, double percent) =>
      width(context) * (percent / 100);

  static double percentHeight(BuildContext context, double percent) =>
      height(context) * (percent / 100);

  final BuildContext context;
  final Size? _layoutSize;

  MediaQueryData get _mediaQuery => MediaQuery.of(context);
  Size get _size => _layoutSize ?? _mediaQuery.size;
  EdgeInsets get _padding => _mediaQuery.padding;
  EdgeInsets get _viewInsets => _mediaQuery.viewInsets;

  double get screenWidth => _size.width;
  double get screenHeight => _size.height;
  double get viewInsetBottom => _layoutSize == null ? _viewInsets.bottom : 0;
  double get safeTopInset => _layoutSize == null ? _padding.top : 0;
  double get safeBottomInset => _layoutSize == null ? _padding.bottom : 0;
  double get availableWidth =>
      math.max(0, screenWidth - (horizontalPadding * 2));
  double get availableHeight =>
      math.max(0, screenHeight - (verticalPadding * 2));
  double get keyboardAwareAvailableHeight =>
      math.max(0, screenHeight - safeTopInset - safeBottomInset - viewInsetBottom);
  double get safeContentHeight =>
      math.max(0, screenHeight - safeTopInset - safeBottomInset);

  Orientation get orientation => _mediaQuery.orientation;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isTablet => math.min(screenWidth, screenHeight) >= 600;
  bool get isSmallTablet =>
      isTablet && math.min(screenWidth, screenHeight) < 800;
  bool get isMobile => !isTablet;

  double get textScaleFactor => _mediaQuery.textScaler.scale(1);

  EdgeInsets get contentPadding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );

  double get sectionGap => spacingLg;

  double get horizontalPadding {
    final base = screenWidth * (isTablet ? 0.04 : 0.05);

    return (base + (_layoutSize == null ? _padding.left + _padding.right : 0))
        .clamp(16, 36);
  }

  double get verticalPadding {
    final base = screenHeight * (isTablet ? 0.022 : 0.02);

    return (base + (_layoutSize == null ? _padding.top + _padding.bottom : 0))
        .clamp(12, 24);
  }

  double get cardWidth {
    if (isLandscape) {
      return (screenWidth * 0.38).clamp(340, 520);
    }

    return (screenWidth * 0.9).clamp(300, 560);
  }

  double get buttonHeight => (screenHeight * 0.072).clamp(52, 72);

  double get iconSize =>
      (math.min(screenWidth, screenHeight) * 0.05).clamp(18, 32);

  double get keypadButtonSize {
    final available = cardWidth - (spacingMd * 2);
    final size = (available - (spacingSm * 2)) / 3;

    return size.clamp(64, 104);
  }

  double get titleFontSize => (screenWidth * 0.05).clamp(24, 34);
  double get bodyFontSize => (screenWidth * 0.024).clamp(14, 18);
  double get captionFontSize => (screenWidth * 0.02).clamp(11, 14);

  double get panelGap => spacingMd;

  Axis get orderLayoutDirection => isPortrait ? Axis.vertical : Axis.horizontal;

  double get categoryPanelWidthPercent => isPortrait ? 1 : 0.24;
  double get productsPanelWidthPercent => isPortrait ? 1 : 0.46;
  double get currentOrderPanelWidthPercent => isPortrait ? 1 : 0.30;

  double get categoryButtonHeight => isPortrait
      ? (screenHeight * 0.055).clamp(38, 46)
      : (screenHeight * 0.07).clamp(48, 60);

  double get categoryButtonFontSize => isPortrait
      ? (screenWidth * 0.021).clamp(12, 14)
      : (screenWidth * 0.024).clamp(13, 17);

  double get orderPanelWidth =>
      (availableWidth * currentOrderPanelWidthPercent).clamp(280, 360);

  double get orderPanelMinHeight =>
      isPortrait ? (availableHeight * 0.30).clamp(210, 280) : availableHeight;

  double get orderPanelCompactHeight =>
      isPortrait ? (availableHeight * 0.24).clamp(176, 220) : availableHeight;

  double get orderPanelExpandedHeight =>
      isPortrait ? (availableHeight * 0.42).clamp(280, 380) : availableHeight;

  double get orderActionButtonHeight =>
      isPortrait ? (screenHeight * 0.056).clamp(40, 48) : buttonHeight;

  double get orderTitleFontSize => isPortrait
      ? (screenWidth * 0.03).clamp(17, 22)
      : (screenWidth * 0.034).clamp(20, 28);

  double get orderBodyFontSize => isPortrait
      ? (screenWidth * 0.021).clamp(12, 15)
      : (screenWidth * 0.023).clamp(13, 17);

  double get orderTotalFontSize => isPortrait
      ? (screenWidth * 0.034).clamp(20, 26)
      : (screenWidth * 0.03).clamp(18, 24);

  int get productGridColumns {
    if (isPortrait) {
      if (screenWidth < 700) {
        return 2;
      }

      return 2;
    }

    if (screenWidth >= 1300) {
      return 3;
    }

    return 2;
  }

  double get productCardHeight {
    final columns = productGridColumns;
    final availableGridWidth = math.max(
      0,
      availableWidth - ((columns - 1) * spacingMd),
    );
    final cardWidth = availableGridWidth / columns;

    if (isPortrait) {
      return (cardWidth * 1.02).clamp(150, 190);
    }

    return cardWidth.clamp(220, 300);
  }

  double get productCardAspectRatio {
    final columns = productGridColumns;
    final availableGridWidth = math.max(
      0,
      availableWidth - ((columns - 1) * spacingMd),
    );
    final cardWidth = availableGridWidth / columns;

    return cardWidth / productCardHeight;
  }

  double get productListCardPadding => isPortrait
      ? (screenWidth * 0.034).clamp(12, 14)
      : (screenWidth * 0.022).clamp(12, 16);

  double get productListImageSize => isPortrait
      ? (screenWidth * 0.22).clamp(82, 92)
      : (screenHeight * 0.16).clamp(88, 108);

  double get productListImagePadding => isPortrait
      ? (productListImageSize * 0.11).clamp(8, 10)
      : (productListImageSize * 0.10).clamp(9, 12);

  double get productListCardRadius => isPortrait ? 28 : 24;

  double get productListImageRadius => isPortrait ? 22 : 20;

  double get productListAddButtonSize => isPortrait
      ? (screenWidth * 0.11).clamp(42, 46)
      : (screenHeight * 0.075).clamp(42, 52);

  double get productListNameFontSize => isPortrait
      ? (screenWidth * 0.044).clamp(16, 18)
      : (screenWidth * 0.022).clamp(16, 20);

  double get productListPriceFontSize => isPortrait
      ? (screenWidth * 0.048).clamp(18, 20)
      : (screenWidth * 0.026).clamp(18, 22);

  double get productListCardMinHeight =>
      productListImageSize + (productListCardPadding * 2);

  int get tableGridColumns {
    if (isPortrait) {
      if (screenWidth < 700) {
        return 2;
      }

      return 3;
    }

    if (screenWidth >= 1400) {
      return 5;
    }

    if (screenWidth >= 1100) {
      return 4;
    }

    if (screenWidth >= 800) {
      return 3;
    }

    return 2;
  }

  double get _tableGridSpacing => spacingMd;

  double get tableCardHeight {
    final columns = tableGridColumns;
    final availableWidth = math.max(
      0,
      screenWidth -
          (horizontalPadding * 2) -
          ((columns - 1) * _tableGridSpacing),
    );
    final cardWidth = availableWidth / columns;

    if (isPortrait) {
      return cardWidth.clamp(170, 220);
    }

    return cardWidth.clamp(180, 240);
  }

  double get tableCardAspectRatio {
    final columns = tableGridColumns;
    final availableWidth = math.max(
      0,
      screenWidth -
          (horizontalPadding * 2) -
          ((columns - 1) * _tableGridSpacing),
    );
    final cardWidth = availableWidth / columns;

    return cardWidth / tableCardHeight;
  }

  double get spacingXs => isPortrait
      ? (screenWidth * 0.01).clamp(4, 8)
      : (screenWidth * 0.012).clamp(6, 10);

  double get spacingSm => isPortrait
      ? (screenWidth * 0.016).clamp(8, 12)
      : (screenWidth * 0.02).clamp(10, 14);

  double get spacingMd => isPortrait
      ? (screenWidth * 0.022).clamp(10, 16)
      : (screenWidth * 0.03).clamp(14, 20);

  double get spacingLg => (screenWidth * 0.045).clamp(20, 28);

  double get spacingXl => (screenWidth * 0.06).clamp(24, 36);

  double get productDetailSheetRadius => productListCardRadius;

  double get productDetailHeroImageHeight => isPortrait
      ? (screenHeight * 0.16).clamp(112, 132)
      : (screenHeight * 0.18).clamp(108, 132);

  double get productDetailComplementImageSize =>
      productListImageSize.clamp(56, 74);

  double get productDetailCounterButtonSize => isPortrait
      ? (screenWidth * 0.095).clamp(38, 42)
      : (screenHeight * 0.07).clamp(38, 44);

  double get productDetailFooterButtonHeight => buttonHeight.clamp(52, 56);

  double get loginHorizontalPadding => isTablet
      ? (screenWidth * 0.05).clamp(24, 40)
      : (screenWidth * 0.06).clamp(18, 24);

  double get loginTopSpacing => isPortrait
      ? (safeContentHeight * 0.035).clamp(16, 28)
      : (keyboardAwareAvailableHeight * 0.02).clamp(8, 16);

  double get loginHeaderGap => isPortrait
      ? (safeContentHeight * 0.014).clamp(8, 14)
      : (keyboardAwareAvailableHeight * 0.012).clamp(6, 10);

  double get loginCardTopGap => isPortrait
      ? (safeContentHeight * 0.026).clamp(14, 24)
      : (keyboardAwareAvailableHeight * 0.018).clamp(8, 16);

  double get loginFooterGap => isPortrait
      ? (safeContentHeight * 0.026).clamp(14, 24)
      : (keyboardAwareAvailableHeight * 0.016).clamp(8, 14);

  double get loginLogoSize => isPortrait
      ? (screenWidth * 0.28).clamp(92.0, 124.0)
      : (keyboardAwareAvailableHeight * 0.17).clamp(72.0, 98.0);

  double get loginCardHorizontalPadding => isPortrait
      ? (screenWidth * 0.065).clamp(18.0, 28.0)
      : (screenWidth * 0.04).clamp(18.0, 24.0);

  double get loginCardVerticalPadding => isPortrait
      ? (safeContentHeight * 0.027).clamp(18.0, 26.0)
      : (keyboardAwareAvailableHeight * 0.022).clamp(12.0, 18.0);

  double get loginPinDotSize => isPortrait
      ? (screenWidth * 0.092).clamp(28.0, 42.0)
      : (screenWidth * 0.05).clamp(22.0, 30.0);

  double get loginCardInnerGapSm => isPortrait
      ? (safeContentHeight * 0.018).clamp(10.0, 18.0)
      : (keyboardAwareAvailableHeight * 0.014).clamp(8.0, 12.0);

  double get loginCardInnerGapXs => isPortrait
      ? (safeContentHeight * 0.010).clamp(6.0, 10.0)
      : (keyboardAwareAvailableHeight * 0.010).clamp(4.0, 8.0);

  double get loginCardInnerGapLg => isPortrait
      ? (safeContentHeight * 0.030).clamp(16.0, 24.0)
      : (keyboardAwareAvailableHeight * 0.018).clamp(10.0, 16.0);

  double get loginCardInnerGapMd => isPortrait
      ? (safeContentHeight * 0.022).clamp(12.0, 18.0)
      : (keyboardAwareAvailableHeight * 0.016).clamp(8.0, 14.0);

  double get loginTitleFontSize => isPortrait
      ? (screenWidth * 0.064).clamp(24.0, 32.0)
      : (screenWidth * 0.042).clamp(20.0, 28.0);

  double get loginBusinessTitleFontSize => isPortrait
      ? (screenWidth * 0.068).clamp(26.0, 34.0)
      : (screenWidth * 0.046).clamp(22.0, 30.0);

  double get loginSubtitleFontSize => isPortrait
      ? (screenWidth * 0.036).clamp(13.0, 18.0)
      : (screenWidth * 0.024).clamp(12.0, 15.0);

  double get loginSupportFontSize => isPortrait
      ? (screenWidth * 0.039).clamp(14.0, 18.0)
      : (screenWidth * 0.026).clamp(12.0, 16.0);

  double get recentActivityBodyHeight => isPortrait
      ? (screenHeight * 0.19).clamp(168.0, 178.0)
      : (screenHeight * 0.16).clamp(118.0, 140.0);

  double get scrollBottomSafePadding => safeBottomInset + spacingLg;

  double get bottomSheetContentPadding => safeBottomInset + 16;

  double get categorySheetListBottomPadding => safeBottomInset + 12;

  double get landscapeRecentActivitySectionHeight => isPortrait
      ? recentActivityBodyHeight
      : (screenHeight * 0.28).clamp(180.0, 260.0);
}
