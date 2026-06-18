import 'package:flutter/material.dart';

import '../config/business_config.dart';

class AppColors {
  // MARCA DEL CLIENTE
  static Color get primary => BusinessConfig.current.primaryColor;
  static Color get secondary => BusinessConfig.current.secondaryColor;
  static Color get accent => BusinessConfig.current.accentColor;

  // FONDO APP
  static Color get appBackground => BusinessConfig.current.surfaceColor;
  static Color get surface => BusinessConfig.current.surfaceColor;

  // ESTADOS MESA
  static const Color tableFree = Color(0xFF5D9C6A);
  static const Color tableWithOrder = Color(0xFFE0A72E);
  static const Color tableWaitingPayment = Color(0xFFE05243);

  // ESTADOS GENERALES
  static Color get success => BusinessConfig.current.successColor;
  static Color get warning => BusinessConfig.current.warningColor;
  static Color get danger => BusinessConfig.current.dangerColor;

  // TEXTO
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // UI BASE
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE5EAF0);

  // SUPERFICIES SUAVES
  static const Color softBackground = Color(0xFFF8FAFC);
}