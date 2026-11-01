import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/theme/app_fonts.dart';

/// `flutter test` otherwise measures text with a square-glyph fallback font,
/// which inflates every width and produces overflows the real app never has.
Future<void> loadAppFonts() async {
  final loader = FontLoader(AppFonts.family);
  for (final weight in const [400, 500, 600, 700, 800]) {
    loader.addFont(
      rootBundle
          .load('assets/fonts/PlusJakartaSans-$weight.ttf')
          .then((d) => ByteData.view(d.buffer)),
    );
  }
  await loader.load();
}
