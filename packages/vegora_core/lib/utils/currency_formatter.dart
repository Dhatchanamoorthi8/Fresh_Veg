import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrFormatNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Converts integer paise (e.g. 4500) to formatted currency string (e.g. "₹45")
  static String formatPaise(int paise, {bool showDecimalsIfZero = false}) {
    final rupees = paise / 100.0;
    if (!showDecimalsIfZero && paise % 100 == 0) {
      return _inrFormatNoDecimals.format(rupees);
    }
    return _inrFormat.format(rupees);
  }

  /// Converts rupees (e.g. 45.50) to integer paise (4550)
  static int rupeesToPaise(double rupees) {
    return (rupees * 100).round();
  }
}
