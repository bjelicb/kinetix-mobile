String formatDate(dynamic date) {
  if (date == null) return 'N/A';
  try {
    if (date is String) {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    }
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  } catch (_) {
    return date.toString();
  }
}

String formatDayOfWeek(dynamic dayOfWeek) {
  if (dayOfWeek == null) return '';
  try {
    final day = dayOfWeek is int ? dayOfWeek : int.tryParse(dayOfWeek.toString()) ?? 0;
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (day >= 1 && day <= 7) {
      return days[day];
    }
    return dayOfWeek.toString();
  } catch (_) {
    return dayOfWeek.toString();
  }
}

