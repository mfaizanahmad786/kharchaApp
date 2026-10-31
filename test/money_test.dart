import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/utils/money.dart';

void main() {
  group('South-Asian digit grouping', () {
    test('leaves groups of three or fewer alone', () {
      expect(Money.groupDigits('7'), '7');
      expect(Money.groupDigits('77'), '77');
      expect(Money.groupDigits('776'), '776');
    });

    test('groups the leading digits in twos, not threes', () {
      expect(Money.groupDigits('5776'), '5,776');
      expect(Money.groupDigits('95776'), '95,776');
      expect(Money.groupDigits('295776'), '2,95,776');
      expect(Money.groupDigits('2500000'), '25,00,000');
      expect(Money.groupDigits('123456789'), '12,34,56,789');
    });
  });

  group('format', () {
    test('splits rupees from paisa', () {
      expect(Money.whole(814578), '8,145');
      expect(Money.fraction(814578), '78');
      expect(Money.fraction(814500), '00');
      expect(Money.fraction(814505), '05');
    });

    test('renders the symbol, grouping and decimals', () {
      expect(Money.format(814578), '₨8,145.78');
      expect(Money.format(814578, symbol: false), '8,145.78');
      expect(Money.format(814578, decimals: false), '₨8,145');
    });

    test('carries the sign on negative amounts', () {
      expect(Money.format(-35425), '-₨354.25');
      expect(Money.format(35425, sign: true), '+₨354.25');
      expect(Money.format(-35425, sign: true), '-₨354.25');
    });

    test('never shows a negative zero magnitude twice', () {
      expect(Money.format(-1, decimals: false), '-₨0');
    });
  });

  group('compact', () {
    test('uses thousand, lakh and crore steps', () {
      expect(Money.compact(78400), '₨784');
      expect(Money.compact(8170000), '₨81.7k');
      expect(Money.compact(25000000), '₨2.5L');
      expect(Money.compact(5000000000), '₨5Cr');
    });

    test('keeps the minus sign', () {
      expect(Money.compact(-8170000), '-₨81.7k');
    });
  });

  group('parse', () {
    test('accepts grouped and decimal input', () {
      expect(Money.parse('1,250.50'), 125050);
      expect(Money.parse('1250'), 125000);
      expect(Money.parse('₨ 99.99'), 9999);
    });

    test('rejects input with no digits', () {
      expect(Money.parse(''), isNull);
      expect(Money.parse('abc'), isNull);
    });

    test('rounds rather than truncates the paisa', () {
      expect(Money.parse('10.005'), 1001);
    });
  });

  test('percent is clamped to 0..1', () {
    expect(Money.percent(50, 100), 0.5);
    expect(Money.percent(150, 100), 1.0);
    expect(Money.percent(10, 0), 0.0);
  });
}
