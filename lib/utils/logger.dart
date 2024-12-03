import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(String date) {
    try {
      if (date.isEmpty) return '-';
      
      final DateTime dateTime = DateTime.parse(date);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return date;
    }
  }
}