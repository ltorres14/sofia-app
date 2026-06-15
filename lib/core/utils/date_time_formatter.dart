import 'package:intl/intl.dart';

class DateTimeFormatter {
  static String shortTime(DateTime value) => DateFormat('HH:mm').format(value.toLocal());
  static String shortDate(DateTime value) => DateFormat('dd/MM/yyyy').format(value.toLocal());
}
