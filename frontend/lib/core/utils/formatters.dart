/// Formatting utilities for relative timestamps and compact counts.
class AppFormatters {
  AppFormatters._();

  /// Formats [dateTime] into a relative human-readable timestamp (e.g. "Just now", "5m", "2h", "3d").
  static String formatRelativeTime(DateTime dateTime, [DateTime? clock]) {
    final now = clock ?? DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 365) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }

  /// Compact formatting for metrics (e.g. 1200 -> "1.2K", 1000000 -> "1M").
  static String formatCompactNumber(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final double inK = count / 1000.0;
      return inK >= 10
          ? '${inK.toStringAsFixed(0)}K'
          : '${inK.toStringAsFixed(1)}K';
    } else {
      final double inM = count / 1000000.0;
      return inM >= 10
          ? '${inM.toStringAsFixed(0)}M'
          : '${inM.toStringAsFixed(1)}M';
    }
  }
}
