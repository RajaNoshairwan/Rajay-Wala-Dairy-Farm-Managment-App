import 'package:intl/intl.dart';

class AppDateUtils {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _monthFmt = DateFormat('MMMM yyyy');
  static final _shortFmt = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime d) => _dateFmt.format(d);
  static String formatMonth(DateTime d) => _monthFmt.format(d);
  static String short(DateTime d) => _shortFmt.format(d);

  static DateTime normalize(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}