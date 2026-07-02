import 'package:flutter/material.dart';

/// Typographic scale for the game. Uses the platform default font family for
/// zero-asset builds, but centralises weights, sizes and letter-spacing so the
/// look stays consistent and can be swapped to a custom font in one place.
class AppTextStyles {
  const AppTextStyles._();

  static const String? _family = null; // swap to a bundled font family later.

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.05,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  /// Tabular figures look right in animated counters (coins/score).
  static const TextStyle counter = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
