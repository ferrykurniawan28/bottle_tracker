extension DateTimeExtension on DateTime {
  /// Convert UTC datetime to UTC+7
  /// If the datetime is already in UTC, adds 7 hours
  DateTime toUtcPlus7() {
    if (isUtc) {
      return add(const Duration(hours: 7));
    }
    // If not UTC, assume it's UTC and convert
    return toUtc().add(const Duration(hours: 7));
  }

  /// Alias for toUtcPlus7() for better readability
  DateTime toLocalTime() => toUtcPlus7();
}

/// Standalone function to convert UTC to UTC+7
DateTime convertUtcToUtcPlus7(DateTime utcDateTime) {
  return utcDateTime.toUtcPlus7();
}

/// Standalone function for better null-safety
DateTime? convertUtcToUtcPlus7Nullable(DateTime? utcDateTime) {
  if (utcDateTime == null) return null;
  return utcDateTime.toUtcPlus7();
}
