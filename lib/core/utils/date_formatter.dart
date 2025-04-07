import 'package:intl/intl.dart';

/// Utility class for consistent date formatting across the app
class DateFormatter {
  /// Format a DateTime to a human-readable date (e.g., "Mar 15, 2023")
  static String formatReadableDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Format a DateTime to include time (e.g., "Mar 15, 2023 3:30 PM")
  static String formatDateWithTime(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  /// Format a date relative to today (e.g., "Today", "Yesterday", or formatted date)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return formatReadableDate(date);
    }
  }

  /// Format a DateTime from an ISO8601 string
  static String formatFromIso8601(String isoString) {
    final date = DateTime.parse(isoString);
    return formatReadableDate(date);
  }
} 