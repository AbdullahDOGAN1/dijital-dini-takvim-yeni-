import os
import re

path = 'lib/services/daily_content_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace file content from top to avoid syntax errors
new_content = '''// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/daily_content_model.dart';
import '../models/prayer_times_model.dart';

class DailyContentService {
  static List<DailyContentModel>? _cachedContent;

  /// JSON dosyasından günlük içerikleri yükler
  static Future<List<DailyContentModel>> loadDailyContent() async {
    _cachedContent = null;
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/nurvakti_genel_takvim.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedContent = jsonList
          .map((json) => DailyContentModel.fromJson(json))
          .toList();
      return _cachedContent!;
    } catch (e) {
      print('Günlük içerik yüklenirken hata: \');
      return [];
    }
  }

  /// Belirli bir güne ait içeriği getir (1-365 arası)
  static Future<DailyContentModel?> getContentForDay(int dayNumber) async {
    if (dayNumber < 1 || dayNumber > 365) {
      return null;
    }

    if (_cachedContent == null || _cachedContent!.isEmpty) {
      await loadDailyContent();
    }

    try {
      return _cachedContent!.firstWhere((item) => item.gunNo == dayNumber);
    } catch (e) {
      return null;
    }
  }

  /// Bugünün içeriğini getir
  static Future<DailyContentModel?> getTodaysContent() async {
    final now = DateTime.now();
    final dayOfYear = _getDayOfYear(now);
    return await getContentForDay(dayOfYear);
  }

  /// Verilen tarihin yılın kaçıncı günü olduğunu hesapla
  static int _getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  /// Rastgele bir günlük içerik getir
  static Future<DailyContentModel?> getRandomContent() async {
    final content = await loadDailyContent();
    if (content.isEmpty) return null;

    final randomIndex = DateTime.now().millisecondsSinceEpoch % content.length;
    return content[randomIndex];
  }

  static const _turkishHijriMonths = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce',
  ];

  /// Offline hijri calculation
  static Future<HijriDate?> getAccurateHijriDate(DateTime gregorianDate) async {
    try {
      final hDate = HijriCalendar.fromDate(gregorianDate);
      final monthName = _turkishHijriMonths[hDate.hMonth - 1];
      
      final shortDate = '\.\.\';
      final longDate = '\ \ \';

      return HijriDate(
        date: longDate,
        format: 'DD MMMM YYYY',
        day: hDate.hDay.toString(),
        weekday: '',
        month: monthName,
        year: hDate.hYear.toString(),
        designation: '',
        holidays: [],
      );
    } catch (e) {
      if (kDebugMode) print('Hijri date error: \');
      return null;
    }
  }

  static final Map<String, HijriDate> _hijriCache = {};

  static Future<HijriDate?> getCachedHijriDate(DateTime gregorianDate) async {
    final dateKey = '\-\-\';
    if (_hijriCache.containsKey(dateKey)) {
      return _hijriCache[dateKey];
    }

    final hijriDate = await getAccurateHijriDate(gregorianDate);
    if (hijriDate != null) {
      _hijriCache[dateKey] = hijriDate;
    }
    return hijriDate;
  }

  static Future<DailyContentModel?> getTodaysContentWithHijri() async {
    final now = DateTime.now();
    final dayOfYear = _getDayOfYear(now);
    return await getContentForDay(dayOfYear);
  }
}
'''
with open(path, 'w', encoding='utf-8') as f:
    f.write(new_content)

