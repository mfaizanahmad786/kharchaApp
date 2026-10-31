/// Money is stored everywhere as an integer number of paisa (1/100 of a rupee)
/// so no rounding error can ever creep into a balance.
library;

const String kCurrencySymbol = '₨'; // ₨

abstract final class Money {
  /// Pakistani / South-Asian digit grouping: the last three digits form one
  /// group, everything above that is grouped in twos. 295776 -> "2,95,776".
  static String groupDigits(String digits) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  /// The rupee part, grouped. Sign is dropped — callers render it themselves.
  static String whole(int paisa) => groupDigits((paisa.abs() ~/ 100).toString());

  /// The two-digit paisa part, without a separator.
  static String fraction(int paisa) =>
      (paisa.abs() % 100).toString().padLeft(2, '0');

  /// "₨8,145.78" — the plain one-piece form.
  static String format(
    int paisa, {
    bool symbol = true,
    bool decimals = true,
    bool sign = false,
  }) {
    final buf = StringBuffer();
    if (sign) {
      buf.write(paisa < 0 ? '-' : '+');
    } else if (paisa < 0) {
      buf.write('-');
    }
    if (symbol) buf.write(kCurrencySymbol);
    buf.write(whole(paisa));
    if (decimals) buf..write('.')..write(fraction(paisa));
    return buf.toString();
  }

  /// Short form for dense places: ₨8.1k, ₨1.2L, ₨3.4Cr.
  static String compact(int paisa, {bool symbol = true}) {
    final rupees = paisa.abs() / 100;
    final s = paisa < 0 ? '-' : '';
    final sym = symbol ? kCurrencySymbol : '';
    String n(double v) =>
        v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    if (rupees >= 10000000) return '$s$sym${n(rupees / 10000000)}Cr';
    if (rupees >= 100000) return '$s$sym${n(rupees / 100000)}L';
    if (rupees >= 1000) return '$s$sym${n(rupees / 1000)}k';
    return '$s$sym${rupees.toStringAsFixed(0)}';
  }

  /// Parses free user input ("1,250.50", "1250") into paisa. Null if unusable.
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null) return null;
    return (value * 100).round();
  }

  static double percent(int part, int whole) =>
      whole == 0 ? 0 : (part / whole).clamp(0.0, 1.0);
}
