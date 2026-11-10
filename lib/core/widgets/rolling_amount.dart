import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../theme/app_palette.dart';
import '../utils/money.dart';

/// The two-tone amount of [AmountText], whose digits roll to their new value
/// like an odometer rather than snapping. Used for the few figures that
/// change while you are looking at them — the balance and the month's
/// spending — so a transaction you just recorded visibly moves the number.
///
/// At rest it is an ordinary [RichText], pixel for pixel what [AmountText]
/// would have drawn. Only a change splits it into glyphs, and the glyphs are
/// placed from the whole string's own layout so the line does not shift as
/// the roll starts: measuring each character on its own loses the kerning
/// between them and the figure would visibly jump.
class RollingAmount extends ConsumerStatefulWidget {
  const RollingAmount(
    this.paisa, {
    super.key,
    required this.style,
    this.color,
    this.showSign = false,
    this.showDecimals = true,
    this.showSymbol = true,
    this.fractionOpacity = 0.55,
    this.duration = const Duration(milliseconds: 650),
  });

  final int paisa;
  final TextStyle style;
  final Color? color;
  final bool showSign;
  final bool showDecimals;
  final bool showSymbol;
  final double fractionOpacity;
  final Duration duration;

  @override
  ConsumerState<RollingAmount> createState() => _RollingAmountState();
}

class _RollingAmountState extends ConsumerState<RollingAmount>
    with SingleTickerProviderStateMixin {
  // One controller drives every digit: a dozen tickers for one figure would
  // cost more than the effect is worth, and they would have to stay in step
  // anyway. Created eagerly rather than `late final`, whose initialiser would
  // otherwise run from dispose() on any build that returned early.
  late final AnimationController _controller;
  late int _previous = widget.paisa;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    // Once the roll is over, collapse back to a single RichText: a settled
    // figure has no reason to be a dozen stacked glyphs.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _previous != widget.paisa) {
        setState(() => _previous = widget.paisa);
      }
    });
  }

  @override
  void didUpdateWidget(RollingAmount old) {
    super.didUpdateWidget(old);
    if (old.paisa == widget.paisa) return;
    _previous = old.paisa;
    _controller
      ..duration = widget.duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(int paisa) {
    final sign = widget.showSign
        ? (paisa < 0 ? '-' : '+')
        : (paisa < 0 ? '-' : '');
    final head =
        '$sign${widget.showSymbol ? kCurrencySymbol : ''}'
        '${Money.whole(paisa)}';
    return widget.showDecimals ? '$head.${Money.fraction(paisa)}' : head;
  }

  /// The rupees at full weight and the paisa dimmed, as everywhere else.
  TextSpan _span(String text, TextStyle base) {
    final dot = widget.showDecimals ? text.lastIndexOf('.') : -1;
    if (dot == -1) return TextSpan(text: text, style: base);
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: text.substring(0, dot)),
        TextSpan(
          text: text.substring(dot),
          style: base.copyWith(
            color: base.color!.withValues(alpha: widget.fractionOpacity),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hidden = ref.watch(settingsProvider.select((s) => s.hideAmounts));
    // Resolve the colour rather than assume one: callers that inherit from
    // the theme pass neither `color` nor a coloured style, and the dimmed
    // paisa cannot be derived from null.
    final resolved =
        widget.color ??
        widget.style.color ??
        DefaultTextStyle.of(context).style.color ??
        context.palette.ink;
    final base = widget.style.copyWith(
      color: resolved,
      // Tabular digits so the line does not jitter as they change.
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (hidden) {
      return Text(
        '${widget.showSymbol ? kCurrencySymbol : ''}••••',
        style: base,
      );
    }

    final text = _format(widget.paisa);
    final previous = _format(_previous);
    final scaler = MediaQuery.textScalerOf(context);
    final span = _span(text, base);

    // Only a same-length string can roll digit for digit; when the amount
    // gains or loses a place every glyph shifts and the roll would read as
    // noise. Reduced motion takes the same path: the figure simply updates.
    final rolls =
        previous != text &&
        previous.length == text.length &&
        !MediaQuery.disableAnimationsOf(context);
    if (!rolls) return RichText(textScaler: scaler, text: span);

    // Lay the whole string out once and take each character's box from it,
    // so the split figure occupies exactly the space the settled one did.
    final painter = TextPainter(
      text: span,
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout();
    final boxes = <Rect>[];
    for (var i = 0; i < text.length; i++) {
      final found = painter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (found.isEmpty) break;
      boxes.add(found.first.toRect());
    }
    final size = painter.size;
    painter.dispose();
    if (boxes.length != text.length) {
      return RichText(textScaler: scaler, text: span);
    }

    final dot = widget.showDecimals ? text.lastIndexOf('.') : -1;
    final fraction = resolved.withValues(alpha: widget.fractionOpacity);
    final goingUp = widget.paisa >= _previous;

    // The split glyphs are a visual device; a screen reader should still hear
    // one amount rather than each digit in turn.
    return Semantics(
      label: text,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              for (var i = 0; i < text.length; i++)
                Positioned(
                  left: boxes[i].left,
                  top: 0,
                  child: _Slot(
                    from: previous[i],
                    to: text[i],
                    style: dot != -1 && i >= dot
                        ? base.copyWith(color: fraction)
                        : base,
                    width: boxes[i].width,
                    height: size.height,
                    goingUp: goingUp,
                    animation: _controller,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.from,
    required this.to,
    required this.style,
    required this.width,
    required this.height,
    required this.goingUp,
    required this.animation,
  });

  final String from;
  final String to;
  final TextStyle style;
  final double width;
  final double height;
  final bool goingUp;
  final Animation<double> animation;

  Widget _glyph(String character) => OverflowBox(
    alignment: Alignment.topLeft,
    maxWidth: double.infinity,
    maxHeight: double.infinity,
    child: Text(character, style: style),
  );

  @override
  Widget build(BuildContext context) {
    // Punctuation never rolls, and neither does a digit that did not change.
    if (from == to || int.tryParse(to) == null) {
      return Text(to, style: style);
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(animation.value);
            // Up when the amount grew, down when it shrank: the direction is
            // the point of the effect. Growing means the new digit rises
            // into place from below while the old one leaves through the
            // top, which on screen is a negative offset.
            final direction = goingUp ? -1.0 : 1.0;
            return Stack(
              children: [
                Transform.translate(
                  offset: Offset(0, t * height * direction),
                  child: _glyph(from),
                ),
                Transform.translate(
                  offset: Offset(0, (t - 1) * height * direction),
                  child: _glyph(to),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
