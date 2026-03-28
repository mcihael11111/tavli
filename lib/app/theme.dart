import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

/// Tavli app theme — 5-color warm palette, Minor Second (1.067) type scale.
///
/// Design system: docs/design/01_DESIGN_SYSTEM.md
/// M3 mapping: docs/design/07_MATERIAL_DESIGN.md
abstract final class TavliTheme {
  /// Serif font family name for headings. Use in inline TextStyle.
  static String get serifFamily => GoogleFonts.playfairDisplay().fontFamily!;

  // ── Light Theme ──────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: TavliColors.primary,
          onPrimary: TavliColors.light,
          primaryContainer: TavliColors.surface,
          onPrimaryContainer: TavliColors.text,
          secondary: TavliColors.surface,
          onSecondary: TavliColors.text,
          secondaryContainer: TavliColors.backgroundHover,
          onSecondaryContainer: TavliColors.text,
          tertiary: TavliColors.primary,
          onTertiary: TavliColors.light,
          surface: TavliColors.surface,
          onSurface: TavliColors.light,
          onSurfaceVariant: TavliColors.primary,
          outline: TavliColors.primary,
          outlineVariant: TavliColors.surface,
          error: TavliColors.error,
          onError: TavliColors.light,
          inverseSurface: TavliColors.text,
          onInverseSurface: TavliColors.light,
          shadow: Colors.black,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: TavliColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: TavliColors.light,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(color: TavliColors.light, size: 24),
        ),
        cardTheme: CardThemeData(
          color: TavliColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            side: const BorderSide(color: TavliColors.background),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: TavliColors.primary,
            foregroundColor: TavliColors.light,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: TavliSpacing.md,
              vertical: TavliSpacing.xs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TavliRadius.sm),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: serifFamily,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TavliColors.primary,
            foregroundColor: TavliColors.light,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: TavliSpacing.lg,
              vertical: TavliSpacing.sm,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TavliRadius.sm),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: serifFamily,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: TavliColors.background,
            foregroundColor: TavliColors.primary,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: TavliColors.primary),
            padding: const EdgeInsets.symmetric(
              horizontal: TavliSpacing.md,
              vertical: TavliSpacing.xs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TavliRadius.sm),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: serifFamily,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: TavliColors.primary,
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: serifFamily,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TavliColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TavliRadius.sm),
            borderSide: const BorderSide(color: TavliColors.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TavliRadius.sm),
            borderSide: const BorderSide(color: TavliColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TavliRadius.sm),
            borderSide: const BorderSide(color: TavliColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TavliRadius.sm),
            borderSide: const BorderSide(color: TavliColors.error, width: 2),
          ),
          labelStyle: const TextStyle(color: TavliColors.text),
          hintStyle: TextStyle(color: TavliColors.text.withValues(alpha: 0.6)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TavliSpacing.md,
            vertical: TavliSpacing.sm,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: TavliColors.background,
          indicatorColor: TavliColors.primary,
          surfaceTintColor: Colors.transparent,
          height: 68,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: TavliColors.light, size: 24);
            }
            return const IconThemeData(color: TavliColors.primary, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TavliColors.primary,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TavliColors.primary,
            );
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.light;
            }
            return TavliColors.background;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.primary;
            }
            return TavliColors.primary.withValues(alpha: 0.4);
          }),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: TavliColors.primary,
          inactiveTrackColor: TavliColors.background,
          thumbColor: TavliColors.background,
          trackHeight: 12,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
        ),
        dividerTheme: DividerThemeData(
          color: TavliColors.primary.withValues(alpha: 0.2),
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: TavliColors.text,
          iconColor: TavliColors.primary,
        ),
        iconTheme: const IconThemeData(
          color: TavliColors.primary,
          size: 24,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: TavliColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TavliRadius.lg),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: TavliColors.text,
            fontFamily: 'Poppins',
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: TavliColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(TavliRadius.lg),
            ),
          ),
        ),
        textTheme: _textTheme,
      );

  // ── Dark Theme ───────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: TavliColors.primaryDark,
          onPrimary: TavliColors.text,
          primaryContainer: TavliColors.surfaceDark,
          onPrimaryContainer: TavliColors.light,
          secondary: TavliColors.surfaceDark,
          onSecondary: TavliColors.light,
          surface: TavliColors.surfaceDark,
          onSurface: TavliColors.light,
          onSurfaceVariant: TavliColors.primaryDark,
          outline: TavliColors.primaryDark,
          outlineVariant: TavliColors.surfaceDark,
          error: TavliColors.error,
          onError: TavliColors.light,
          inverseSurface: TavliColors.light,
          onInverseSurface: TavliColors.text,
          shadow: Colors.black,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: TavliColors.surfaceDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: TavliColors.light,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(color: TavliColors.primaryDark, size: 24),
        ),
        cardTheme: CardThemeData(
          color: TavliColors.surfaceDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            side: const BorderSide(color: TavliColors.primaryDark),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TavliColors.primaryDark,
            foregroundColor: TavliColors.text,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: TavliSpacing.lg,
              vertical: TavliSpacing.sm,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TavliRadius.sm),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: TavliColors.light,
            side: const BorderSide(color: TavliColors.primaryDark),
            padding: const EdgeInsets.symmetric(
              horizontal: TavliSpacing.md,
              vertical: TavliSpacing.xs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TavliRadius.sm),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: TavliColors.surfaceDark,
          surfaceTintColor: Colors.transparent,
          indicatorColor: TavliColors.primaryDark,
          height: 68,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: TavliColors.text, size: 24);
            }
            return const IconThemeData(
                color: TavliColors.primaryDark, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TavliColors.light,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TavliColors.primaryDark,
            );
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.primaryDark;
            }
            return TavliColors.surfaceDark;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TavliColors.surfaceDark;
            }
            return TavliColors.lightDark;
          }),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: TavliColors.primaryDark,
          inactiveTrackColor: TavliColors.surfaceDark,
          thumbColor: TavliColors.primaryDark,
          trackHeight: 12,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
        ),
        dividerTheme: DividerThemeData(
          color: TavliColors.primaryDark.withValues(alpha: 0.2),
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: TavliColors.light,
          iconColor: TavliColors.primaryDark,
        ),
        iconTheme: const IconThemeData(
          color: TavliColors.primaryDark,
          size: 24,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: TavliColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TavliRadius.lg),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: TavliColors.light,
            fontFamily: 'Poppins',
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: TavliColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(TavliRadius.lg),
            ),
          ),
        ),
        textTheme: _darkTextTheme,
      );

  // ── Typography — Serif headings (Playfair Display) + Sans-serif body (Poppins) ──
  static TextTheme get _textTheme {
    final serif = GoogleFonts.playfairDisplayTextTheme();
    return TextTheme(
      // Display: hero text, large numbers — SERIF
      displayLarge: serif.displayLarge!.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        height: 1.24,
        letterSpacing: -0.84,
        color: TavliColors.text,
      ),
      displayMedium: serif.displayMedium!.copyWith(
        fontSize: 31,
        fontWeight: FontWeight.w700,
        height: 1.29,
        letterSpacing: -0.62,
        color: TavliColors.text,
      ),
      displaySmall: serif.displaySmall!.copyWith(
        fontSize: 27,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: -0.27,
        color: TavliColors.text,
      ),
      // Headlines: section/screen titles — SERIF
      headlineLarge: serif.headlineLarge!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: -0.48,
        color: TavliColors.primary,
      ),
      headlineMedium: serif.headlineMedium!.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: -0.42,
        color: TavliColors.primary,
      ),
      headlineSmall: serif.headlineSmall!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: TavliColors.primary,
      ),
      // Titles: component labels, card titles — SERIF
      titleLarge: serif.titleLarge!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.33,
        color: TavliColors.text,
      ),
      titleMedium: serif.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.38,
        letterSpacing: 0.15,
        color: TavliColors.text,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: TavliColors.text,
        fontFamily: 'Poppins',
      ),
      // Body: reading text — SANS-SERIF
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: TavliColors.text,
        fontFamily: 'Poppins',
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
        color: TavliColors.text,
        fontFamily: 'Poppins',
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.4,
        color: TavliColors.text,
        fontFamily: 'Poppins',
      ),
      // Labels: buttons, chips, metadata — SANS-SERIF
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: TavliColors.text,
        fontFamily: 'Poppins',
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
        color: TavliColors.text,
        fontFamily: 'Poppins',
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.5,
        color: TavliColors.primary,
        fontFamily: 'Poppins',
      ),
    );
  }

  static TextTheme get _darkTextTheme {
    final serif = GoogleFonts.playfairDisplayTextTheme();
    return TextTheme(
      // Display — SERIF
      displayLarge: serif.displayLarge!.copyWith(
        fontSize: 42, fontWeight: FontWeight.w700, height: 1.24,
        letterSpacing: -0.84, color: TavliColors.light,
      ),
      displayMedium: serif.displayMedium!.copyWith(
        fontSize: 31, fontWeight: FontWeight.w700, height: 1.29,
        letterSpacing: -0.62, color: TavliColors.light,
      ),
      displaySmall: serif.displaySmall!.copyWith(
        fontSize: 27, fontWeight: FontWeight.w600, height: 1.33,
        letterSpacing: -0.27, color: TavliColors.light,
      ),
      // Headlines — SERIF
      headlineLarge: serif.headlineLarge!.copyWith(
        fontSize: 24, fontWeight: FontWeight.w600, height: 1.33,
        letterSpacing: -0.48, color: TavliColors.primaryDark,
      ),
      headlineMedium: serif.headlineMedium!.copyWith(
        fontSize: 21, fontWeight: FontWeight.w600, height: 1.33,
        letterSpacing: -0.42, color: TavliColors.primaryDark,
      ),
      headlineSmall: serif.headlineSmall!.copyWith(
        fontSize: 18, fontWeight: FontWeight.w600, height: 1.33,
        color: TavliColors.primaryDark,
      ),
      // Titles — SERIF
      titleLarge: serif.titleLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.w500, height: 1.33, color: TavliColors.light),
      titleMedium: serif.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.38, letterSpacing: 0.15, color: TavliColors.light),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1, color: TavliColors.light, fontFamily: 'Poppins'),
      // Body — SANS-SERIF
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: TavliColors.light, fontFamily: 'Poppins'),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, letterSpacing: 0.25, color: TavliColors.light, fontFamily: 'Poppins'),
      bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33, letterSpacing: 0.4, color: TavliColors.light, fontFamily: 'Poppins'),
      // Labels — SANS-SERIF
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1, color: TavliColors.light, fontFamily: 'Poppins'),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0.5, color: TavliColors.light, fontFamily: 'Poppins'),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, letterSpacing: 0.5, color: TavliColors.primaryDark, fontFamily: 'Poppins'),
    );
  }
}
