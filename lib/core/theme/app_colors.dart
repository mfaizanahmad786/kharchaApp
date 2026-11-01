import 'package:flutter/material.dart';

/// Colours that are the same in both appearances.
///
/// Anything whose value depends on the surface behind it — ink, surfaces,
/// borders, shadows, the positive and negative hues — lives in [AppPalette]
/// and is read from the theme as `context.palette`.
abstract final class AppColors {
  // Brand
  //
  // Green is a far more luminous hue than the violet this replaced, so the
  // ramp sits deliberately deeper: a like-for-like swap of the old lightness
  // would have dropped white-on-brand below a readable contrast.
  static const brand = Color(0xFF059669);
  static const brandDark = Color(0xFF047857);
  static const brandLight = Color(0xFF10B981);
  static const brandLighter = Color(0xFF34D399);
  static const brandSoft = Color(0xFFD1FAE5);

  /// The header gradient on Home.
  ///
  /// Deeper than the brand ramp used on white: full-white 16pt text needs
  /// 4.5:1, which the lighter greens could not carry. Worst stop here is
  /// 4.74:1 for the label and 3.36:1 for the dimmed paisa.
  static const headerTop = Color(0xFF04533D);
  static const headerMid = Color(0xFF046A4E);
  static const headerEnd = Color(0xFF058363);

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerTop, headerMid, headerEnd],
  );

  /// Solid fill for pills sitting on the header. A translucent white veil
  /// left its label at 2.94:1; this carries white at 9.09:1.
  static const headerPill = headerTop;

  /// Warning state on goals and budgets.
  static const warning = Color(0xFFE8743B);

  /// Category accents. A chart needs distinct hues whatever the brand is, so
  /// these stay fixed; a category's own colour is user data besides.
  static const catPurple = Color(0xFF8B5CF6);
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
}
