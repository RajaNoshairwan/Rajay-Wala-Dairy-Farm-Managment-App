import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static String format(num amount) => _fmt.format(amount);
}