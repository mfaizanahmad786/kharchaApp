import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The colours that differ between the light and dark appearances.
///
/// `AppColors` keeps everything that does not change — the brand ramp, the
/// header gradient and the category hues — because those are the same in both
/// appearances. Anything whose value depends on the surface behind it lives
/// here and is read from the theme, since a `static const` cannot adapt.
///
/// Read it as `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.scaffold,
    required this.surface,
    required this.surfaceMuted,
    required this.track,
    required this.divider,
    required this.border,
    required this.borderSoft,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.navInactive,
    required this.income,
    required this.expense,
    required this.badgeGreenBg,
    required this.badgeGreenFg,
    required this.badgeRedBg,
    required this.badgeRedFg,
    required this.incomeTint,
    required this.expenseTint,
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
    required this.cardShadow,
    required this.softShadow,
  });

  final Brightness brightness;

  final Color scaffold;
  final Color surface;
  final Color surfaceMuted;
  final Color track;
  final Color divider;
  final Color border;
  final Color borderSoft;

  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color navInactive;

  final Color income;
  final Color expense;
  final Color badgeGreenBg;
  final Color badgeGreenFg;
  final Color badgeRedBg;
  final Color badgeRedFg;
  final Color incomeTint;
  final Color expenseTint;

  final Color chipBg;
  final Color chipBorder;
  final Color chipText;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> softShadow;

  bool get isDark => brightness == Brightness.dark;

  /// A soft wash of [c] for the glyph tiles. In the dark appearance it blends
  /// toward the surface rather than toward white, or the tile glows.
  Color tint(Color c, {double alpha = 0.12}) =>
      Color.alphaBlend(c.withValues(alpha: alpha), surface);

  // ------------------------------------------------------------------ light

  static const light = AppPalette(
    brightness: Brightness.light,
    scaffold: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF7F7F9),
    track: Color(0xFFEFEFF2),
    divider: Color(0xFFECECEF),
    border: Color(0xFFECECF2),
    borderSoft: Color(0xFFE5E5EC),
    ink: Color(0xFF111111),
    inkSoft: Color(0xFF6B6B76),
    inkFaint: Color(0xFF74747E),
    navInactive: Color(0xFF6E6E78),
    income: Color(0xFF047857),
    expense: Color(0xFFE0314B),
    badgeGreenBg: Color(0xFFD1FAE5),
    badgeGreenFg: Color(0xFF047857),
    badgeRedBg: Color(0xFFFDE8EB),
    badgeRedFg: Color(0xFFE0314B),
    incomeTint: Color(0xFFEAF3FF),
    expenseTint: Color(0xFFFDEDEC),
    chipBg: Color(0xFFE6F9F0),
    chipBorder: Color(0xFFA7F3D0),
    chipText: Color(0xFF047857),
    cardShadow: [
      BoxShadow(color: Color(0x0D1A1A2E), blurRadius: 18, offset: Offset(0, 6)),
    ],
    softShadow: [
      BoxShadow(color: Color(0x0A1A1A2E), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );

  // ------------------------------------------------------------------- dark
  // Every foreground here clears 4.5:1 against both the card and the page.
  // Elevation reads through lightness, not shadow, so the shadows all but
  // disappear: a drop shadow on a dark ground only muddies the edge.

  static const dark = AppPalette(
    brightness: Brightness.dark,
    scaffold: Color(0xFF0E1311),
    surface: Color(0xFF171D1A),
    surfaceMuted: Color(0xFF1C2320),
    track: Color(0xFF242B28),
    divider: Color(0xFF2A312E),
    border: Color(0xFF2A312E),
    borderSoft: Color(0xFF333A37),
    ink: Color(0xFFECEFED),
    inkSoft: Color(0xFFA7B0AB),
    inkFaint: Color(0xFF8B938F),
    navInactive: Color(0xFF9AA29E),
    income: Color(0xFF4ADE80),
    expense: Color(0xFFFF7A8A),
    badgeGreenBg: Color(0xFF10301F),
    badgeGreenFg: Color(0xFF4ADE80),
    badgeRedBg: Color(0xFF351317),
    badgeRedFg: Color(0xFFFF7A8A),
    incomeTint: Color(0xFF14283D),
    expenseTint: Color(0xFF331A1D),
    chipBg: Color(0xFF103025),
    chipBorder: Color(0xFF1D5140),
    chipText: Color(0xFF5FD6A6),
    cardShadow: [],
    softShadow: [],
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    // The two appearances swap rather than cross-fade; a half-blended palette
    // is never a state the app should paint.
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppPaletteX on BuildContext {
  /// The colours for the current appearance.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// Kept so the static brand ramp and the palette can be imported together.
typedef Brand = AppColors;
