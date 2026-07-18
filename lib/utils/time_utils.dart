class TimeUtils {
  static String formatDate(int date) {
    if (date < 0) {
      return '公元前 ${-date} 年';
    }
    return '$date 年';
  }

  static String formatDuration(int start, int end) {
    final duration = end - start;
    if (duration < 100) {
      return '$duration 年';
    } else if (duration < 1000) {
      return '${(duration / 100).round()} 世纪';
    } else {
      return '${(duration / 1000).round()} 千年';
    }
  }
}
