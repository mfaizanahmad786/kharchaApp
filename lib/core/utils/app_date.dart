import 'package:intl/intl.dart';

abstract final class AppDate {
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _fullDay = DateFormat('EEEE, d MMMM, yyyy');
  static final _shortDay = DateFormat('d MMM yyyy');
  static final _dayMonth = DateFormat('d MMM');
  static final _time = DateFormat('h:mm a');

  static String monthYear(DateTime d) => _monthYear.format(d);
  static String fullDay(DateTime d) => _fullDay.format(d);
  static String shortDay(DateTime d) => _shortDay.format(d);
  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String time(DateTime d) => _time.format(d);

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);
  static DateTime endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1).subtract(const Duration(milliseconds: 1));
  static DateTime addMonths(DateTime d, int n) =>
      DateTime(d.year, d.month + n, 1);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Today" / "Yesterday" / "Monday, 12 January, 2026"
  static String friendlyDay(DateTime d) {
    final now = DateTime.now();
    if (sameDay(d, now)) return 'Today';
    if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return fullDay(d);
  }

  static int daysBetween(DateTime a, DateTime b) =>
      startOfDay(b).difference(startOfDay(a)).inDays;
}
