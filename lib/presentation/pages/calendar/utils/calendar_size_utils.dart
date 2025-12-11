import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Calendar size calculation result
class CalendarSizes {
  final double maxHeight;
  final double rowHeight;
  final double daysOfWeekHeight;
  final bool isSmallPhone;

  CalendarSizes({
    required this.maxHeight,
    required this.rowHeight,
    required this.daysOfWeekHeight,
    required this.isSmallPhone,
  });
}

/// Calendar responsive sizing utilities
class CalendarSizeUtils {
  /// Calculate responsive calendar sizes based on screen and format
  static CalendarSizes calculateCalendarSizes(BuildContext context, CalendarFormat format) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenHeight < 700 || screenWidth < 360;
    final isTwoWeeks = format == CalendarFormat.twoWeeks;
    final isWeek = format == CalendarFormat.week;

    final maxHeight = format == CalendarFormat.month
        ? screenHeight * (isSmallPhone ? 0.40 : 0.45)
        : isTwoWeeks
            ? screenHeight * (isSmallPhone ? 0.28 : 0.30)
            : screenHeight * (isSmallPhone ? 0.18 : 0.22);

    final rowHeight = format == CalendarFormat.month
        ? (isSmallPhone ? 38.0 : 42.0)
        : isTwoWeeks
            ? (isSmallPhone ? 34.0 : 38.0)
            : (isSmallPhone ? 28.0 : 32.0);

    final daysOfWeekHeight = isSmallPhone
        ? (isWeek ? 16.0 : 18.0)
        : (isWeek ? 18.0 : 22.0);

    return CalendarSizes(
      maxHeight: maxHeight,
      rowHeight: rowHeight,
      daysOfWeekHeight: daysOfWeekHeight,
      isSmallPhone: isSmallPhone,
    );
  }
}

