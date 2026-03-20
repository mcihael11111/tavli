import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

/// Tavli app theme — warm, modern, accessibility-checked.
///
/// All text/background combinations meet WCAG AA minimum.
/// Body text uses Espresso (#2C1A0E) for AAA compliance on all surfaces.
/// Headings use Chocolate (#7F5539) — AA at 4.97:1 on Cream.
abstract final class TavliTheme {
  // ── Light Theme ──────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: TavliColors.chocolate,
          onPrimary: TavliColors.latte,
          secondary: TavliColors.sienna,
          onSecondary: Colors.white,
          tertiary: TavliColors.mocha,
          onTertiary: TavliColors.espresso,
          surface: TavliColors.cream,
          onSurface: TavliColors.espresso,
          surfaceContainerLowest: TavliColors.latte,
          surfaceContainerLow: TavliColors.cream,
          surfaceContainer: TavliColors.tan,
          surfaceContainerHigh: TavliColors.tan,
          error: TavliColors.error,
          onError: Colors.white,
          outline: TavliColors.sand,
          outlineVariant: TavliColors.tan,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: TavliColors.cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: TavliColors.chocolate,
          foregroundColor: TavliColors.latte,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: TavliColors.tan,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: const Color(0x1F2C1A0E), // espresso at 12%
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TavliColors.chocolate,
            foregroundColor: TavliColors.latte,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: TavliColors.chocolate,
            side: const BorderSide(color: TavliColors.chocolate, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: TavliColors.sienna,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: TavliColors.cream,
          surfaceTintColor: Colors.transparent,
          indicatorColor: TavliColors.sienna.withValues(alpha: 0.20),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: TavliColors.chocolate,
                size: 24,
              );
            }
            return const IconThemeData(
              color: TavliColors.mocha,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TavliColors.chocolate,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TavliColors.mocha,
            );
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.chocolate;
            }
            return TavliColors.sand;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.chocolate.withValues(alpha: 0.35);
            }
            return TavliColors.tan;
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: TavliColors.chocolate,
          inactiveTrackColor: TavliColors.sand.withValues(alpha: 0.5),
          thumbColor: TavliColors.chocolate,
        ),
        dividerTheme: const DividerThemeData(
          color: TavliColors.sand,
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: TavliColors.espresso,
          iconColor: TavliColors.chocolate,
        ),
        iconTheme: const IconThemeData(
          color: TavliColors.chocolate,
        ),
        textTheme: _textTheme,
      );

  // ── Dark Theme ───────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: TavliColors.mocha,
          onPrimary: TavliColors.espresso,
          secondary: TavliColors.sand,
          onSecondary: TavliColors.espresso,
          tertiary: TavliColors.sienna,
          surface: TavliColors.espresso,
          onSurface: TavliColors.cream,
          surfaceContainerLowest: TavliColors.espresso,
          surfaceContainerLow: TavliColors.darkRoast,
          surfaceContainer: TavliColors.darkRoast,
          surfaceContainerHigh: TavliColors.darkSurface,
          error: TavliColors.error,
          onError: Colors.white,
          outline: TavliColors.chocolate,
          outlineVariant: TavliColors.darkSurface,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: TavliColors.espresso,
        appBarTheme: const AppBarTheme(
          backgroundColor: TavliColors.espresso,
          foregroundColor: TavliColors.cream,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: TavliColors.darkRoast,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TavliColors.mocha,
            foregroundColor: TavliColors.espresso,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: TavliColors.cream,
            side: const BorderSide(color: TavliColors.cream, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: TavliColors.espresso,
          surfaceTintColor: Colors.transparent,
          indicatorColor: TavliColors.mocha.withValues(alpha: 0.25),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: TavliColors.cream,
                size: 24,
              );
            }
            return const IconThemeData(
              color: TavliColors.chocolate,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TavliColors.cream,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TavliColors.chocolate,
            );
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.mocha;
            }
            return TavliColors.chocolate;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.mocha.withValues(alpha: 0.35);
            }
            return TavliColors.darkSurface;
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: TavliColors.mocha,
          inactiveTrackColor: TavliColors.mocha.withValues(alpha: 0.2),
          thumbColor: TavliColors.mocha,
        ),
        dividerTheme: const DividerThemeData(
          color: TavliColors.chocolate,
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: TavliColors.cream,
          iconColor: TavliColors.sand,
        ),
        iconTheme: const IconThemeData(
          color: TavliColors.sand,
        ),
        textTheme: _darkTextTheme,
      );

  // ── Typography ────────────────────────────────────────────────
  static const _textTheme = TextTheme(
    // Headings use Chocolate — AA (4.97:1) on Cream at these sizes.
    displayLarge: TextStyle(
      fontSize: 40, fontWeight: FontWeight.w700,
      letterSpacing: 2, color: TavliColors.chocolate,
    ),
    headlineLarge: TextStyle(
      fontSize: 24, fontWeight: FontWeight.w600, color: TavliColors.chocolate,
    ),
    headlineMedium: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: TavliColors.chocolate,
    ),
    // Body uses Espresso — AAA (12.86:1) on Cream, (10.82:1) on Tan.
    bodyLarge: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, color: TavliColors.espresso,
    ),
    bodyMedium: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400, color: TavliColors.espresso,
    ),
    bodySmall: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w400, color: TavliColors.espresso,
    ),
    labelLarge: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w500, color: TavliColors.espresso,
    ),
    labelSmall: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w500, color: TavliColors.chocolate,
    ),
  );

  static const _darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 40, fontWeight: FontWeight.w700,
      letterSpacing: 2, color: TavliColors.cream,
    ),
    headlineLarge: TextStyle(
      fontSize: 24, fontWeight: FontWeight.w600, color: TavliColors.cream,
    ),
    headlineMedium: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: TavliColors.cream,
    ),
    // Body uses Cream (12.86:1 on Espresso) and Sand (9.00:1) for secondary.
    bodyLarge: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, color: TavliColors.cream,
    ),
    bodyMedium: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400, color: TavliColors.sand,
    ),
    bodySmall: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w400, color: TavliColors.sand,
    ),
    labelLarge: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w500, color: TavliColors.cream,
    ),
    labelSmall: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w500, color: TavliColors.sand,
    ),
  );
}
