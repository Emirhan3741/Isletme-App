import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Tarihi yerelleştirilmiş formatta döndürür
  static String formatDate(DateTime date, Locale locale) {
    return DateFormat.yMd(locale.languageCode).format(date);
  }

  /// Saati yerelleştirilmiş formatta döndürür
  static String formatTime(DateTime time, Locale locale) {
    return DateFormat.Hm(locale.languageCode).format(time);
  }

  /// Tarih ve saati birlikte yerelleştirilmiş formatta döndürür
  static String formatDateTime(DateTime dateTime, Locale locale) {
    return DateFormat.yMd(locale.languageCode).add_Hm().format(dateTime);
  }

  /// Tam tarih formatı (örn: "15 Ocak 2024, Pazartesi")
  static String formatFullDate(DateTime date, Locale locale) {
    return DateFormat.yMMMMEEEEd(locale.languageCode).format(date);
  }

  /// Ay ve yıl formatı (örn: "Ocak 2024")
  static String formatMonthYear(DateTime date, Locale locale) {
    return DateFormat.yMMMM(locale.languageCode).format(date);
  }

  /// Kısa tarih formatı (örn: "15 Oca")
  static String formatShortDate(DateTime date, Locale locale) {
    return DateFormat.MMMd(locale.languageCode).format(date);
  }

  /// Göreli tarih formatı (örn: "2 gün önce", "yarın")
  static String formatRelativeDate(DateTime date, Locale locale) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return _getLocalizedString('today', locale);
    } else if (difference == 1) {
      return _getLocalizedString('tomorrow', locale);
    } else if (difference == -1) {
      return _getLocalizedString('yesterday', locale);
    } else if (difference > 1 && difference <= 7) {
      return DateFormat.EEEE(locale.languageCode).format(date);
    } else {
      return formatDate(date, locale);
    }
  }

  /// Süre formatı (örn: "2 saat 30 dakika")
  static String formatDuration(Duration duration, Locale locale) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours ${_getLocalizedString('hours', locale)} $minutes ${_getLocalizedString('minutes', locale)}';
    } else {
      return '$minutes ${_getLocalizedString('minutes', locale)}';
    }
  }

  /// Yaş hesaplama
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// İş günü kontrolü (Pazartesi-Cuma)
  static bool isWorkDay(DateTime date) {
    return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
  }

  /// Hafta sonu kontrolü
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Bu ayın başlangıcını döndürür
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Bu ayın sonunu döndürür
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Bu haftanın başlangıcını döndürür (Pazartesi)
  static DateTime getStartOfWeek(DateTime date) {
    final difference = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: difference));
  }

  /// Bu haftanın sonunu döndürür (Pazar)
  static DateTime getEndOfWeek(DateTime date) {
    final difference = DateTime.sunday - date.weekday;
    return date.add(Duration(days: difference));
  }

  /// Para formatı (yerel para birimi ile)
  static String formatCurrency(double amount, Locale locale,
      {String? currencyCode}) {
    final format = NumberFormat.currency(
      locale: locale.languageCode,
      symbol: _getCurrencySymbol(locale, currencyCode),
    );
    return format.format(amount);
  }

  /// Sayı formatı (binlik ayırıcı ile)
  static String formatNumber(double number, Locale locale) {
    final format = NumberFormat.decimalPattern(locale.languageCode);
    return format.format(number);
  }

  /// Yüzde formatı
  static String formatPercentage(double percentage, Locale locale) {
    final format = NumberFormat.percentPattern(locale.languageCode);
    return format.format(percentage / 100);
  }

  /// Dil-specific string'ler için basit mapping
  static String _getLocalizedString(String key, Locale locale) {
    final strings = {
      'tr': {
        'today': 'Bugün',
        'tomorrow': 'Yarın',
        'yesterday': 'Dün',
        'hours': 'saat',
        'minutes': 'dakika',
      },
      'en': {
        'today': 'Today',
        'tomorrow': 'Tomorrow',
        'yesterday': 'Yesterday',
        'hours': 'hours',
        'minutes': 'minutes',
      },
      'de': {
        'today': 'Heute',
        'tomorrow': 'Morgen',
        'yesterday': 'Gestern',
        'hours': 'Stunden',
        'minutes': 'Minuten',
      },
      'fr': {
        'today': 'Aujourd\'hui',
        'tomorrow': 'Demain',
        'yesterday': 'Hier',
        'hours': 'heures',
        'minutes': 'minutes',
      },
      'es': {
        'today': 'Hoy',
        'tomorrow': 'Mañana',
        'yesterday': 'Ayer',
        'hours': 'horas',
        'minutes': 'minutos',
      },
      'it': {
        'today': 'Oggi',
        'tomorrow': 'Domani',
        'yesterday': 'Ieri',
        'hours': 'ore',
        'minutes': 'minuti',
      },
      'ru': {
        'today': 'Сегодня',
        'tomorrow': 'Завтра',
        'yesterday': 'Вчера',
        'hours': 'часов',
        'minutes': 'минут',
      },
      'ar': {
        'today': 'اليوم',
        'tomorrow': 'غداً',
        'yesterday': 'أمس',
        'hours': 'ساعات',
        'minutes': 'دقائق',
      },
    };

    return strings[locale.languageCode]?[key] ?? strings['en']![key]!;
  }

  /// Para birimi sembolü döndürür
  static String _getCurrencySymbol(Locale locale, String? currencyCode) {
    if (currencyCode != null) {
      return currencyCode;
    }

    switch (locale.languageCode) {
      case 'tr':
        return '₺';
      case 'en':
        return '\$';
      case 'de':
      case 'fr':
      case 'es':
      case 'it':
        return '€';
      case 'ru':
        return '₽';
      case 'ar':
        return 'ر.س';
      default:
        return '\$';
    }
  }

  /// RTL diller için tarih formatını ayarlar
  static bool isRTL(Locale locale) {
    return locale.languageCode == 'ar';
  }

  /// Takvim sistem türünü döndürür
  static String getCalendarSystem(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'hijri'; // İsteğe bağlı olarak Hicri takvim desteği
      default:
        return 'gregorian';
    }
  }
}
