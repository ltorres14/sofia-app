import 'package:flutter/material.dart';

class BusinessConfig {
  const BusinessConfig({
    required this.businessName,
    required this.businessSubtitle,
    required this.businessType,
    required this.logoAssetPath,
    required this.loginBackgroundAssetPath,
    required this.placeholderProductAssetPath,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
    required this.surfaceColor,
    required this.footerText,
    required this.currencySymbol,
    required this.defaultTaxPercent,
    required this.showSofiaBranding,
  });

  final String businessName;
  final String businessSubtitle;
  final String businessType;
  final String logoAssetPath;
  final String loginBackgroundAssetPath;
  final String placeholderProductAssetPath;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;
  final Color surfaceColor;
  final String footerText;
  final String currencySymbol;
  final double defaultTaxPercent;
  final bool showSofiaBranding;

  static const BusinessConfig current = BusinessConfig(
    businessName: 'La Casita del Marisco',
    businessSubtitle: 'Mariscos | Restaurante',
    businessType: 'seafood',
    logoAssetPath: 'assets/images/businesses/seafood/logo.png',
    loginBackgroundAssetPath:
        'assets/images/businesses/seafood/login_background.png',
    placeholderProductAssetPath:
        'assets/images/businesses/seafood/placeholder_product.png',
    primaryColor: Color(0xFF0D3B66),
    secondaryColor: Color(0xFFF4EFE6),
    accentColor: Color(0xFF1F7A8C),
    successColor: Color(0xFF2E9E5B),
    warningColor: Color(0xFFF4A261),
    dangerColor: Color(0xFFD1495B),
    surfaceColor: Color(0xFFF8FAFC),
    footerText: 'SOFÍA Check | Sistema de punto de venta',
    currencySymbol: '\$',
    defaultTaxPercent: 0,
    showSofiaBranding: true,
  );
}
