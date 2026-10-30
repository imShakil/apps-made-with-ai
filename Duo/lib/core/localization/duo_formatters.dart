import 'package:intl/intl.dart';
import 'duo_strings.dart';

class DuoFormatters {
  DuoFormatters._();

  static const Map<String, String> _bnDigits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  /// Converts any number or string containing ASCII digits to Bengali numerals if locale is 'bn'.
  static String formatNumber(dynamic value, String locale) {
    final str = value?.toString() ?? '0';
    if (locale != 'bn') return str;

    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      buffer.write(_bnDigits[char] ?? char);
    }
    return buffer.toString();
  }

  /// Formats days count with localized number and unit.
  static String formatDays(int days, String locale) {
    final numStr = formatNumber(days, locale);
    if (locale == 'bn') {
      return '$numStr দিন';
    }
    return '$numStr ${days == 1 ? 'day' : 'days'}';
  }

  /// Formats countdown units (days, hours, minutes).
  static String formatHours(int hours, String locale) {
    final numStr = formatNumber(hours, locale);
    return locale == 'bn' ? '$numStr ঘণ্টা' : '$numStr hrs';
  }

  static String formatMinutes(int minutes, String locale) {
    final numStr = formatNumber(minutes, locale);
    return locale == 'bn' ? '$numStr মিনিট' : '$numStr mins';
  }

  /// Formats a DateTime with localized month and day.
  static String formatDate(DateTime date, String locale, {bool includeYear = true}) {
    try {
      final pattern = includeYear ? 'MMM d, yyyy' : 'MMM d';
      final formatted = DateFormat(pattern).format(date);
      return formatNumber(formatted, locale);
    } catch (_) {
      return date.toString().split(' ')[0];
    }
  }

  /// Returns time-aware greeting key based on current hour.
  static String getTimeGreetingKey() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'greeting_morning';
    } else if (hour >= 12 && hour < 17) {
      return 'greeting_afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'greeting_evening';
    } else {
      return 'greeting_night';
    }
  }

  /// Returns localized time-aware greeting string.
  static String getTimeGreeting(String locale) {
    return DuoStrings.get(getTimeGreetingKey(), locale);
  }
}
