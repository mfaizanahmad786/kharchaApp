import 'package:flutter/material.dart';

/// Radii, spacing and elevation used across the app, so no screen has to
/// invent its own.
abstract final class AppRadii {
  static const card = 24.0;
  static const tile = 16.0;
  static const sheet = 32.0;
  static const nav = 28.0;
  static const chip = 999.0;

  static const cardShape = BorderRadius.all(Radius.circular(card));
  static const tileShape = BorderRadius.all(Radius.circular(tile));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
  static const navTop = BorderRadius.vertical(top: Radius.circular(nav));
}

abstract final class AppSpacing {
  /// Horizontal gutter for every screen.
  static const screen = 20.0;

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;

  /// Gap between two cards sitting side by side.
  static const cardGap = 12.0;

  static const screenPadding = EdgeInsets.symmetric(horizontal: screen);
}

abstract final class AppSizes {
  static const avatar = 52.0;
  static const bellButton = 48.0;
  static const circleButton = 34.0;
  static const summaryGlyph = 48.0;
  static const txnGlyph = 56.0;
  static const insightBanner = 56.0;
  static const fab = 64.0;
}
