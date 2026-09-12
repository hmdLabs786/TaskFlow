class SmartDateParser {
  static DateTime? parse(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lower.contains('today') || lower.contains('tonight')) {
      return today;
    }

    if (lower.contains('tomorrow') || lower.contains('tmrw') || lower.contains('tmr')) {
      return today.add(const Duration(days: 1));
    }

    if (lower.contains('next week')) {
      return today.add(const Duration(days: 7));
    }

    if (lower.contains('next month')) {
      return DateTime(now.year, now.month + 1, now.day);
    }

    if (lower.contains('next monday')) return _nextWeekday(now, DateTime.monday);
    if (lower.contains('next tuesday')) return _nextWeekday(now, DateTime.tuesday);
    if (lower.contains('next wednesday')) return _nextWeekday(now, DateTime.wednesday);
    if (lower.contains('next thursday')) return _nextWeekday(now, DateTime.thursday);
    if (lower.contains('next friday')) return _nextWeekday(now, DateTime.friday);
    if (lower.contains('next saturday')) return _nextWeekday(now, DateTime.saturday);
    if (lower.contains('next sunday')) return _nextWeekday(now, DateTime.sunday);

    final inDaysMatch = RegExp(r'in (\d+) days?').firstMatch(lower);
    if (inDaysMatch != null) {
      final days = int.parse(inDaysMatch.group(1)!);
      return today.add(Duration(days: days));
    }

    final inWeeksMatch = RegExp(r'in (\d+) weeks?').firstMatch(lower);
    if (inWeeksMatch != null) {
      final weeks = int.parse(inWeeksMatch.group(1)!);
      return today.add(Duration(days: weeks * 7));
    }

    final datePatterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      RegExp(r'(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)'),
    ];

    final fullDateMatch = datePatterns[0].firstMatch(lower);
    if (fullDateMatch != null) {
      final month = int.parse(fullDateMatch.group(1)!);
      final day = int.parse(fullDateMatch.group(2)!);
      var year = now.year;
      if (fullDateMatch.group(3) != null) {
        final y = int.parse(fullDateMatch.group(3)!);
        year = y < 100 ? 2000 + y : y;
      }
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    final monthMap = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    for (final entry in monthMap.entries) {
      if (lower.contains(entry.key)) {
        final dayMatch = RegExp(r'(\d{1,2})').firstMatch(
          lower.substring(lower.indexOf(entry.key)),
        );
        final day = dayMatch != null ? int.parse(dayMatch.group(1)!) : now.day;
        return DateTime(now.year, entry.value, day);
      }
    }

    return null;
  }

  static DateTime _nextWeekday(DateTime now, int weekday) {
    int daysUntil = weekday - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return DateTime(now.year, now.month, now.day).add(Duration(days: daysUntil));
  }

  static String cleanTitle(String text) {
    String cleaned = text;
    final patterns = [
      r'\b(tomorrow|tmrw|tmr)\b',
      r'\b(today|tonight)\b',
      r'\bnext\s+(week|month|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      r'\bin\s+\d+\s+days?\b',
      r'\bin\s+\d+\s+weeks?\b',
      r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
    ];
    for (final p in patterns) {
      cleaned = cleaned.replaceAll(RegExp(p, caseSensitive: false), '');
    }
    return cleaned.trim();
  }
}
