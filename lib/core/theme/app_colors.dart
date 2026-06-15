import 'package:flutter/material.dart';

import '../config/business_config.dart';

class AppColors {
  static Color get primary => BusinessConfig.current.primaryColor;
  static Color get secondary => BusinessConfig.current.secondaryColor;
  static Color get accent => BusinessConfig.current.accentColor;
  static Color get success => BusinessConfig.current.successColor;
  static Color get warning => BusinessConfig.current.warningColor;
  static Color get danger => BusinessConfig.current.dangerColor;
  static Color get surface => BusinessConfig.current.surfaceColor;
  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF52606D);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFD9E2EC);
}
