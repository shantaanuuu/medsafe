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

  /// High contrast background and theme colors matching modern healthcare reference
  Color get backgroundColor => const Color(0xFFF8FAFC);
  Color get cardColor => Colors.white;
  Color get textColor => const Color(0xFF111827); // Slate 900
  Color get secondaryTextColor => const Color(0xFF6B7280); // Gray 500
  Color get borderColor => const Color(0xFFE5E7EB); // Gray 200

  // Primary medical blue
  Color get primaryBlue => const Color(0xFF2563EB);
  Color get primaryTeal => const Color(0xFF2563EB); // Alias for compatibility

  // Functional Alert Colors
  Color get alertRed => const Color(0xFFDC2626);
  Color get warmAmber => const Color(0xFFD97706);
  Color get successGreen => const Color(0xFF16A34A);
  Color get purpleAccent => const Color(0xFF7C3AED);

  // Soft Pastel Icon & Card Backgrounds
  Color get pastelBlue => const Color(0xFFE8F0FF);
  Color get pastelGreen => const Color(0xFFDDF7E8);
  Color get pastelGray => const Color(0xFFEEF1F5);
  Color get pastelYellow => const Color(0xFFFFF4D6);
  Color get pastelRed => const Color(0xFFFFE7E7);
  Color get pastelPurple => const Color(0xFFF3E8FF);

  /// Return dynamic TextStyle with scaled size.
  TextStyle getTextStyle({
    required double baseSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: scaleText(baseSize),
      fontWeight: fontWeight,
      color: color ?? textColor,
      height: height,
      letterSpacing: letterSpacing,
      fontFamily: 'Inter',
    );
  }

  /// Predefined typography getters for convenience
  TextStyle get bodyText => getTextStyle(baseSize: 16.0);
  TextStyle get headerText => getTextStyle(baseSize: 24.0, fontWeight: FontWeight.bold);
  TextStyle get labelText => getTextStyle(baseSize: 14.0, fontWeight: FontWeight.w600);
  TextStyle get captionText => getTextStyle(baseSize: 12.0, color: secondaryTextColor);
}
