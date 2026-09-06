import 'package:intl/intl.dart';

class AppDateFormatter {
  /// Parses a raw date string safely, handling ISO8601, MySQL formats, etc.
  static DateTime? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw.trim();

    // Direct ISO / standard parse
    try {
      return DateTime.parse(clean).toLocal();
    } catch (_) {}

    // Try parsing common MySQL formats: "2026-09-06 14:20:00"
    try {
      final mysqlFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      return mysqlFormat.parse(clean, true).toLocal();
    } catch (_) {}

    // Try date-only format: "2026-09-06"
    try {
      final dateOnly = DateFormat('yyyy-MM-dd');
      return dateOnly.parse(clean, true).toLocal();
    } catch (_) {}

    return null;
  }

  /// Formats ticket scan time cleanly:
  /// - If scanned today: "Today at 2:30 PM"
  /// - If scanned yesterday: "Yesterday at 2:30 PM"
  /// - If another date: "Sep 6, 2026 · 2:30 PM"
  static String formatScannedAt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = parse(raw);
    if (parsed == null) {
      // If parsing fails, clean any trailing microseconds or T/Z if possible
      final clean = raw.replaceAll('T', ' ').replaceAll('Z', '');
      return clean.length > 19 ? clean.substring(0, 19) : clean;
    }

    final now = DateTime.now();
    final isToday = parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = parsed.year == yesterday.year && parsed.month == yesterday.month && parsed.day == yesterday.day;

    final timeStr = DateFormat('h:mm a').format(parsed);

    if (isToday) {
      return 'Today at $timeStr';
    } else if (isYesterday) {
      return 'Yesterday at $timeStr';
    } else if (parsed.year == now.year) {
      final dateStr = DateFormat('MMM d').format(parsed);
      return '$dateStr at $timeStr';
    } else {
      final dateStr = DateFormat('MMM d, y').format(parsed);
      return '$dateStr · $timeStr';
    }
  }

  /// Formats event date & time cleanly, e.g. "Sun, Sep 6, 2026 · 7:00 PM"
  static String formatEventDateTime(String? rawDate, String? rawTime) {
    if (rawDate == null || rawDate.trim().isEmpty) return '—';
    final parsed = parse(rawDate);

    String datePart = rawDate;
    if (parsed != null) {
      datePart = DateFormat('EEE, MMM d, y').format(parsed);
    }

    if (rawTime != null && rawTime.trim().isNotEmpty) {
      return '$datePart · ${rawTime.trim()}';
    }
    return datePart;
  }

  /// Formats standard short date, e.g. "Sep 6, 2026"
  static String formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = parse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, y').format(parsed);
  }
}
