import 'package:intl/intl.dart';

/// Human-friendly, plain-language date/time helpers for a 60+ audience.
class Formatting {
  Formatting._();

  /// e.g. "Just now", "10:30", "Yesterday", "Mon", "3 Apr".
  static String messageTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    if (isToday) return DateFormat('HH:mm').format(dt);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    if (isYesterday) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('d MMM').format(dt);
  }

  /// e.g. "Sunday · 10:30".
  static String activityWhen(DateTime dt) {
    return '${DateFormat('EEEE').format(dt)} · ${DateFormat('HH:mm').format(dt)}';
  }

  /// e.g. "Sun 5 Apr · 10:30".
  static String activityWhenShort(DateTime dt) {
    return '${DateFormat('EEE d MMM').format(dt)} · ${DateFormat('HH:mm').format(dt)}';
  }
}
