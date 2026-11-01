/// The app's typeface, named once.
///
/// Every `TextStyle` that needs to state a family reads this, so changing the
/// face is a single edit here plus the asset block in `pubspec.yaml` — it was
/// previously spelled out as a literal in ten files.
abstract final class AppFonts {
  static const family = 'PlusJakartaSans';
}
