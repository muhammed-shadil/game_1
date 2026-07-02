import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the Material 3 [ThemeData] for light and dark modes from the shared
/// palette + type scale. Screens should read colours from `Theme.of(context)`
/// rather than referencing [AppColors] directly, so theming stays swappable.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      error: AppColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.ink : AppColors.surfaceLight,
      splashFactory: InkSparkle.splashFactory,
    );

    final onSurface = scheme.onSurface;

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            displayLarge: AppTextStyles.display,
            headlineMedium: AppTextStyles.headline,
            titleLarge: AppTextStyles.title,
            bodyMedium: AppTextStyles.body,
            labelLarge: AppTextStyles.button,
            labelMedium: AppTextStyles.label,
          )
          .apply(bodyColor: onSurface, displayColor: onSurface),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceLightAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
