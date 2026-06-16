import 'package:flutter/material.dart';

import '../config/business_config.dart';

class AppColors {
  // PRINCIPAL (más naranja)
  static const Color primaryAmber = Color(0xFFE67E22);

  // OSCURO PARA HOVER / DETALLE
  static const Color primaryAmberDark = Color(0xFFB85C00);

  // FONDO APP
  static const Color appBackground = Color(0xFFF8F4EE);

  // ESTADOS MESA
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

  // TEXTO
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // UI
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE8DDD1);

  // NUEVOS
  static const Color softOrange = Color(0xFFFFE8CC);
  static const Color softBackground = Color(0xFFFFFAF5);
}
