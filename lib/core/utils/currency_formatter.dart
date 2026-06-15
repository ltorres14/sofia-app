import 'package:intl/intl.dart';

import '../config/business_config.dart';

class CurrencyFormatter {
  static String format(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: BusinessConfig.current.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
