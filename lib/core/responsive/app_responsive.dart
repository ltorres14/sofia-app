import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._(this.context, {Size? layoutSize}) : _layoutSize = layoutSize;

  factory AppResponsive.of(BuildContext context, {Size? layoutSize}) =>
      AppResponsive._(context, layoutSize: layoutSize);

  final BuildContext context;
  final Size? _layoutSize;

  MediaQueryData get _mediaQuery => MediaQuery.of(context);
  Size get _size => _layoutSize ?? _mediaQuery.size;
  EdgeInsets get _padding => _mediaQuery.padding;

  double get screenWidth => _size.width;
  double get screenHeight => _size.height;
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

  double get spacingXs => (screenWidth * 0.012).clamp(6, 10);
  double get spacingSm => (screenWidth * 0.02).clamp(10, 14);
  double get spacingMd => (screenWidth * 0.03).clamp(14, 20);
  double get spacingLg => (screenWidth * 0.045).clamp(20, 28);
  double get spacingXl => (screenWidth * 0.06).clamp(24, 36);
}
