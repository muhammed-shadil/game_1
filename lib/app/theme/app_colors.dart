import 'package:flutter/material.dart';

/// The game's premium colour palette.
///
/// Colours are defined once here and consumed via [AppTheme] / [ColorScheme]
/// wherever possible. Gradient + game-world colours that don't map cleanly onto
/// Material's [ColorScheme] are exposed as static constants.
class AppColors {
  const AppColors._();

  // Brand ---------------------------------------------------------------------
  static const Color primary = Color(0xFF5B7CFA); // periwinkle blue
  static const Color primaryDeep = Color(0xFF3B4FD8);
  static const Color secondary = Color(0xFFFF8A5B); // warm coral
  static const Color tertiary = Color(0xFF3ED0C4); // teal accent
  static const Color success = Color(0xFF4CD07A);
  static const Color warning = Color(0xFFFFC24B);
  static const Color danger = Color(0xFFFF5C7A);

  // Neutrals (dark theme base) ------------------------------------------------
  static const Color ink = Color(0xFF0E1230); // near-black indigo
  static const Color surfaceDark = Color(0xFF171B3D);
  static const Color surfaceDarkAlt = Color(0xFF1F2450);
  static const Color surfaceLight = Color(0xFFF6F7FF);
  static const Color surfaceLightAlt = Color(0xFFFFFFFF);

  // Star / reward -------------------------------------------------------------
  static const Color star = Color(0xFFFFD24C);
  static const Color starDim = Color(0xFF4A4E6B);

  // Sky / world gradients -----------------------------------------------------
  static const List<Color> skyDay = [Color(0xFF6DB3FF), Color(0xFFCDE8FF)];
  static const List<Color> skyDusk = [Color(0xFF3B4FD8), Color(0xFFFF8A5B)];
  static const List<Color> menuBackdrop = [
    Color(0xFF1B1F45),
    Color(0xFF0E1230),
  ];

  // Colourblind-friendly alternate accents (Okabe–Ito derived) ----------------
  static const Color cbBlue = Color(0xFF0072B2);
  static const Color cbOrange = Color(0xFFE69F00);
  static const Color cbGreen = Color(0xFF009E73);

  /// A soft translucent white used for glassy surfaces over gradients.
  static const Color glass = Color(0x22FFFFFF);
  static const Color glassStroke = Color(0x33FFFFFF);
}
