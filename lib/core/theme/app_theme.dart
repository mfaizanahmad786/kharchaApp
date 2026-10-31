import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const _font = 'Inter';

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _font,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.purple,
        surface: AppColors.surface,
        error: AppColors.expense,
      ),
    );

    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: _font,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    );
  }

  static TextTheme _textTheme(TextTheme base) => base
      .apply(
        fontFamily: _font,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      )
      .copyWith(
        displayLarge: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.4),
        displayMedium: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.6),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleSmall: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkFaint),
      );
}
