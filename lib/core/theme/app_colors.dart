import 'package:flutter/material.dart';

import '../config/business_config.dart';

class AppColors {
  static const Color primaryAmber = Color(0xFFB7791F);
  static const Color primaryAmberDark = Color(0xFF7C4A12);
  static const Color appBackground = Color(0xFFF7F1E6);
  static const Color tableFree = Color(0xFF5D9C6A);
  static const Color tableWithOrder = Color(0xFFE0A72E);
  static const Color tableWaitingPayment = Color(0xFFE05243);

  static Color get primary => primaryAmber;
  static Color get secondary => BusinessConfig.current.secondaryColor;
  static Color get accent => primaryAmberDark;
  static Color get success => BusinessConfig.current.successColor;
  static Color get warning => BusinessConfig.current.warningColor;
  static Color get danger => BusinessConfig.current.dangerColor;
  static Color get surface => appBackground;
  static const Color textPrimary = Color(0xFF1E1B16);
  static const Color textSecondary = Color(0xFF6F6658);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE8DDCC);
}
