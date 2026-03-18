// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/daily_content_model.dart';
import '../models/prayer_times_model.dart';
import 'diyanet_awqat_salah_service.dart';

class DailyContentService {
  static List<DailyContentModel>? _cachedContent;
  static final DiyanetAwqatSalahService _diyanetService = DiyanetAwqatSalahService();

  /// JSON dosyasından günlük içerikleri yükler
  static Future<List<DailyContentModel>> loadDailyContent() async {
    // Cache'i her zaman temizle (güncellenmiş veri için)
    _cachedContent = null;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/veri_seti_365_gun_vecizeler_temiz.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedContent = jsonList
          .map((json) => DailyContentModel.fromJson(json))
          .toList();
      return _cachedContent!;
    } catch (e) {
      print('Günlük içerik yüklenirken hata: $e');
      return [];
    }
  }

  /// Belirli bir güne ait içeriği getir (1-365 arası)
  static Future<DailyContentModel?> getContentForDay(int dayNumber) async {
    if (dayNumber < 1 || dayNumber > 365) {
      return null;
    }

    final content = await loadDailyContent();
    try {
      return content.firstWhere((item) => item.gunNo == dayNumber);
    } catch (e) {
      print('$dayNumber numaralı gün için içerik bulunamadı: $e');
      return null;
    }
  }

  /// Bugünün tarihine göre içeriği getir
  /// Önce Diyanet API'den dener, başarısız olursa JSON dosyasından okur
  static Future<DailyContentModel?> getTodaysContent() async {
    try {
      // Önce Diyanet API'den dene
      final diyanetContent = await getDailyContentFromDiyanet();
      if (diyanetContent != null) {
        if (kDebugMode) {
          print('✅ Günlük içerik Diyanet API\'den alındı');
        }
        return diyanetContent;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Diyanet API başarısız, JSON dosyasından okunuyor: $e');
      }
    }

    // Fallback: JSON dosyasından oku
    final now = DateTime.now();
    final dayOfYear = _getDayOfYear(now);
    return await getContentForDay(dayOfYear);
  }

  /// Yılın kaçıncı günü olduğunu hesaplar
  static int _getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final difference = date.difference(startOfYear).inDays;
    return difference + 1;
  }

  /// Cache'i temizle (gerekirse yeniden yüklemek için)
  static void clearCache() {
    _cachedContent = null;
  }

  /// Arama yapabilmek için tüm içerikleri getir
  static Future<List<DailyContentModel>> searchContent(String query) async {
    final content = await loadDailyContent();
    final lowercaseQuery = query.toLowerCase();

    return content.where((item) {
      return item.tarih.toLowerCase().contains(lowercaseQuery) ||
          item.ayetHadis.metin.toLowerCase().contains(lowercaseQuery) ||
          item.tariheBugun.toLowerCase().contains(lowercaseQuery) ||
          item.risaleINur.vecize.toLowerCase().contains(lowercaseQuery) ||
          item.aksamYemegi.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Rastgele bir günlük içerik getir
  static Future<DailyContentModel?> getRandomContent() async {
    final content = await loadDailyContent();
    if (content.isEmpty) return null;

    final randomIndex = DateTime.now().millisecondsSinceEpoch % content.length;
    return content[randomIndex];
  }

  /// Diyanet API kullanarak verilen Gregorian tarih için doğru Hijri tarihi getir
  static Future<HijriDate?> getAccurateHijriDate(DateTime gregorianDate) async {
    try {
      final dateStr = '${gregorianDate.year}-${gregorianDate.month.toString().padLeft(2, '0')}-${gregorianDate.day.toString().padLeft(2, '0')}';
      
      final hijriData = await _diyanetService.getHijriCalendar(gregorianDate: dateStr);
      
      if (hijriData != null) {
        return HijriDate(
          date: hijriData['hijriDateShort'] ?? hijriData['hijriDateLong'] ?? '',
          format: 'DD.MM.YYYY',
          day: hijriData['hijriDateShort']?.split('.')[0] ?? '',
          weekday: '',
          month: hijriData['hijriDateLong']?.split(' ')[1] ?? '',
          year: hijriData['hijriDateShort']?.split('.')[2] ?? '',
          designation: '',
          holidays: [],
        );
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hijri tarih alınırken hata: $e');
      }
      return null;
    }
  }

  /// Diyanet API'den günlük içeriği getir (Ayet, Hadis, Dua)
  static Future<DailyContentModel?> getDailyContentFromDiyanet({
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      
      final apiData = await _diyanetService.getDailyContent(date: dateStr);
      
      if (apiData != null) {
        // Diyanet API response formatını DailyContentModel'e çevir
        // API response: {data: {verse, verseSource, hadith, hadithSource, prayer, prayerSource}, success: true}
        final data = apiData['data'] ?? apiData;
        
        // JSON dosyasından gelen format ile uyumlu hale getir
        return DailyContentModel(
          gunNo: _getDayOfYear(targetDate),
          tarih: '${targetDate.day} ${_getMonthName(targetDate.month)} ${targetDate.year}',
          ayetHadis: AyetHadis(
            metin: data['verse'] ?? data['hadith'] ?? '',
            kaynak: data['verseSource'] ?? data['hadithSource'] ?? '',
          ),
          risaleINur: RisaleINur(
            vecize: data['prayer'] ?? '',
            kaynak: data['prayerSource'] ?? '',
          ),
          tariheBugun: '', // Diyanet API'de bu bilgi yok, boş bırak
          aksamYemegi: '', // Diyanet API'de bu bilgi yok, boş bırak
        );
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Diyanet API\'den günlük içerik alınırken hata: $e');
      }
      return null;
    }
  }

  /// Ay ismini getir
  static String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Bilinmeyen';
  }

  /// Cache'lenmiş Hijri tarih için basit önbellek sistemi
  static final Map<String, HijriDate> _hijriCache = {};

  /// Önbellekli Hijri tarih hesaplama
  static Future<HijriDate?> getCachedHijriDate(DateTime gregorianDate) async {
    final dateKey =
        '${gregorianDate.year}-${gregorianDate.month}-${gregorianDate.day}';

    if (_hijriCache.containsKey(dateKey)) {
      return _hijriCache[dateKey];
    }

    final hijriDate = await getAccurateHijriDate(gregorianDate);
    if (hijriDate != null) {
      _hijriCache[dateKey] = hijriDate;
    }

    return hijriDate;
  }

  /// Bugünün tarihine göre içeriği getir (doğru Hijri tarih ile)
  static Future<DailyContentModel?> getTodaysContentWithHijri() async {
    final now = DateTime.now();
    final dayOfYear = _getDayOfYear(now);
    final content = await getContentForDay(dayOfYear);

    if (content != null) {
      // Diyanet API'den doğru Hijri tarihi al
      final hijriDate = await getCachedHijriDate(now);
      if (hijriDate != null) {
        // İçeriğin Hijri tarihini güncelle (eğer model destekliyorsa)
        print('Bugünün Hijri tarihi: ${hijriDate.formattedDate}');
      }
    }

    return content;
  }
}
