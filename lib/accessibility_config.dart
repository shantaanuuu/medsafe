import 'package:flutter/material.dart';

class AccessibilityConfig {
  /// Check if elderly mode is enabled.
  final bool isElderlyMode;

  const AccessibilityConfig({required this.isElderlyMode});

  /// Scale text sizes up by 25% if in Elderly Mode.
  double scaleText(double baseSize) {
    return isElderlyMode ? baseSize * 1.25 : baseSize;
  }

  /// Scale layouts, paddings, and button sizes.
  double scaleSpacing(double baseSpacing) {
    return isElderlyMode ? baseSpacing * 1.2 : baseSpacing;
  }

  /// Minimum tap target size for all interactive items: 48dp (standard) or 56dp in Elderly Mode.
  double get minTapTargetSize => isElderlyMode ? 56.0 : 48.0;

  /// High contrast background colors
  Color get backgroundColor => const Color(0xFFF8FAFC);
  Color get textColor => const Color(0xFF1E293B);
  Color get primaryTeal => const Color(0xFF0F766E);
  Color get alertRed => const Color(0xFFDC2626);
  Color get warmAmber => const Color(0xFFF59E0B);
  Color get successGreen => const Color(0xFF16A34A);

  /// Return dynamic TextStyle with scaled size.
  TextStyle getTextStyle({
    required double baseSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: scaleText(baseSize),
      fontWeight: fontWeight,
      color: color ?? textColor,
      height: height,
      fontFamily: 'Inter',
    );
  }

  /// Predefined typography getters for convenience
  TextStyle get bodyText => getTextStyle(baseSize: 16.0);
  TextStyle get headerText => getTextStyle(baseSize: 24.0, fontWeight: FontWeight.bold);
  TextStyle get labelText => getTextStyle(baseSize: 14.0, fontWeight: FontWeight.w600);
  TextStyle get captionText => getTextStyle(baseSize: 12.0);
}
