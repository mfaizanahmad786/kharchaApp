import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_palette.dart';

abstract final class AppTheme {
  static const _font = AppFonts.family;

  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final brightness = p.brightness;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _font,
      scaffoldBackgroundColor: p.scaffold,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.brand,
            brightness: brightness,
          ).copyWith(
            primary: AppColors.brand,
            surface: p.surface,
            error: p.expense,
          ),
    );

    return base.copyWith(
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(base.textTheme, p),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: p.isDark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.surfaceMuted : p.ink,
        contentTextStyle: TextStyle(
          fontFamily: _font,
          color: p.isDark ? p.ink : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
    );
  }

  /// Each override is merged onto the *applied* base rather than replacing it:
  /// a bare `TextStyle` in `copyWith` would drop the family and colour set by
  /// `apply`, and a null text colour paints white.
  static TextTheme _textTheme(TextTheme base, AppPalette p) {
    final t = base.apply(
      fontFamily: _font,
      bodyColor: p.ink,
      displayColor: p.ink,
    );
    return t.copyWith(
      displayLarge: t.displayLarge!.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
      displayMedium: t.displayMedium!.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
      headlineMedium: t.headlineMedium!.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      titleLarge: t.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: t.titleMedium!.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleSmall: t.titleSmall!.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyLarge: t.bodyLarge!.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: t.bodyMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: t.bodySmall!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: p.inkSoft,
      ),
      labelLarge: t.labelLarge!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: t.labelMedium!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: t.labelSmall!.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: p.inkFaint,
      ),
    );
  }
}
