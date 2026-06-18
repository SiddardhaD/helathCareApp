import 'package:flutter/material.dart';

/// Centralized color palette for the app.
///
/// Design intent: a calm, clinical "white + green" palette that reads as
/// trustworthy and medical without feeling cold. Green is used for primary
/// actions and positive health states; white/soft grey for surfaces; amber
/// and red are reserved strictly for warning/critical states so they retain
/// their urgency signal.
class AppColors {
  AppColors._();

  // Brand / primary
  static const Color primary = Color(0xFF2E9E6B); // medical green
  static const Color primaryDark = Color(0xFF1F7A52);
  static const Color primaryLight = Color(0xFFE3F5EC);
  static const Color primaryLighter = Color(0xFFF2FBF7);

  // Secondary accent (calming blue-teal, used sparingly for info states)
  static const Color secondary = Color(0xFF3E8DBF);
  static const Color secondaryLight = Color(0xFFE6F2F9);

  // Surfaces
  static const Color background = Color(0xFFFAFCFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F7F6);
  static const Color border = Color(0xFFE2E8E6);

  // Text
  static const Color textPrimary = Color(0xFF1A2421);
  static const Color textSecondary = Color(0xFF5C6B66);
  static const Color textTertiary = Color(0xFF8B9994);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic / status
  static const Color success = Color(0xFF2E9E6B);
  static const Color successLight = Color(0xFFE3F5EC);
  static const Color warning = Color(0xFFE6A23C);
  static const Color warningLight = Color(0xFFFCF1E0);
  static const Color critical = Color(0xFFD64545);
  static const Color criticalLight = Color(0xFFFBE7E7);
  static const Color info = Color(0xFF3E8DBF);
  static const Color infoLight = Color(0xFFE6F2F9);

  // Medication / dose tag colors (rotating palette for visual differentiation)
  static const List<Color> doseTagColors = [
    Color(0xFF2E9E6B),
    Color(0xFF3E8DBF),
    Color(0xFF8B6FC9),
    Color(0xFFD68A3C),
    Color(0xFFC9527A),
  ];

  // Shadows
  static const Color shadow = Color(0x14000000);
}
