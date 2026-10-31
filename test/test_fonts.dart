import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// `flutter test` otherwise measures text with a square-glyph fallback font,
/// which inflates every width and produces overflows the real app never has.
Future<void> loadInter() async {
  final loader = FontLoader('Inter');
  for (final weight in const [
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
  ]) {
    loader.addFont(
      rootBundle
          .load('assets/fonts/Inter-$weight.ttf')
          .then((d) => ByteData.view(d.buffer)),
    );
  }
  await loader.load();
}
