import 'package:flutter/material.dart';

/// Palette lifted from the Kharcha design comps.
abstract final class AppColors {
  // Brand
  static const purple = Color(0xFF8B5CF6);
  static const purpleDark = Color(0xFF7C4DEF);
  static const purpleLight = Color(0xFFA78BFA);
  static const purpleLighter = Color(0xFFB79DF9);
  static const purpleSoft = Color(0xFFEDE7FE);

  /// The lavender "For the Period" chip.
  static const chipBg = Color(0xFFEFE9FD);
  static const chipBorder = Color(0xFFDCCFFA);
  static const chipText = Color(0xFF7C4DDB);

  /// The header gradient on Home — a soft diagonal violet wash.
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, purpleLight, purpleLighter],
  );

  // Surfaces
  static const scaffold = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F7F9);
  static const track = Color(0xFFEFEFF2);
  static const divider = Color(0xFFECECEF);
  static const ink = Color(0xFF111111);
  static const inkSoft = Color(0xFF6B6B76);
  static const inkFaint = Color(0xFF9A9AA6);

  /// Hairline borders carry the card edges on Home, in place of shadows.
  static const border = Color(0xFFECECF2);
  static const borderSoft = Color(0xFFE5E5EC);

  /// The inactive tab in the bottom bar.
  static const navInactive = Color(0xFF8E8E99);

  /// The muted trailing action on the black insight banner.
  static const onDarkMuted = Color(0xFF9A9AA5);

  /// Tints behind the income and expense glyphs.
  static const incomeTint = Color(0xFFEAF3FF);
  static const expenseTint = Color(0xFFFDEDEC);

  // Semantic
  static const income = Color(0xFF2FB573);
  static const expense = Color(0xFFE0314B);
  static const warning = Color(0xFFE8743B);
  static const badgeGreenBg = Color(0xFFE4F6EC);
  static const badgeGreenFg = Color(0xFF2FB573);
  static const badgeRedBg = Color(0xFFFDE8EB);
  static const badgeRedFg = Color(0xFFE0314B);

  /// Category accents, matched to the donut chart in the Report comp.
  static const catPurple = purple;
  static const catBlue = Color(0xFF4A9BF0);
  static const catGreen = Color(0xFF4CBF7F);
  static const catOrange = Color(0xFFE8743B);
  static const catPink = Color(0xFFEC6A9C);
  static const catTeal = Color(0xFF2CBFBF);
  static const catAmber = Color(0xFFF0B429);
  static const catIndigo = Color(0xFF5B6CF0);

  static const chartPalette = <Color>[
    catPurple,
    catBlue,
    catGreen,
    catOrange,
    catPink,
    catTeal,
    catAmber,
    catIndigo,
  ];

  /// Soft tinted background used behind category/account glyphs.
  static Color tint(Color c) =>
      Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white);

  // Elevation
  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D1A1A2E), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const softShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0A1A1A2E), blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const navShadow = <BoxShadow>[
    BoxShadow(color: Color(0x141A1A2E), blurRadius: 24, offset: Offset(0, -2)),
  ];
}
