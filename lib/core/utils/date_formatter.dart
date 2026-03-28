import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt.toLocal());

  static String formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt.toLocal());

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM, hh:mm a').format(dt.toLocal());

  static String formatShortDate(DateTime dt) => DateFormat('dd MMM').format(dt.toLocal());

  static String formatWeekDay(DateTime dt) => DateFormat('EEE').format(dt.toLocal());

  static String formatChartLabel(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String relative(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(local);
  }
}
