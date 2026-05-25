import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String rupiah(num value) {
    return _rupiah.format(value);
  }

  static String dailyPrice(num value) {
    return '${rupiah(value)}/hari';
  }
}