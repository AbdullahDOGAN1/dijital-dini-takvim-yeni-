import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/daily_content_model.dart';
import '../models/prayer_times_model.dart';
import 'aladhan_api_service.dart';

class DailyContentService {
  static List<DailyContentModel>? _cachedContent;
  static final AlAdhanApiService _alAdhanService = AlAdhanApiService();

  /// JSON dosyasından günlük içerikleri yükler
  static Future<List<DailyContentModel>> loadDailyContent() async {
    if (_cachedContent != null) {
      return _cachedContent!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/veri_seti_365_gun.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _cachedContent = jsonList.map((json) => DailyContentModel.fromJson(json)).toList();
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
  static Future<DailyContentModel?> getTodaysContent() async {
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
             item.tarihteBugun.toLowerCase().contains(lowercaseQuery) ||
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

  /// AlAdhan API kullanarak verilen Gregorian tarih için doğru Hijri tarihi getir
  static Future<HijriDate?> getAccurateHijriDate(DateTime gregorianDate) async {
    try {
      return await _alAdhanService.getHijriDate(gregorianDate: gregorianDate);
    } catch (e) {
      print('Hijri tarih alınırken hata: $e');
      return null;
    }
  }

  /// Cache'lenmiş Hijri tarih için basit önbellek sistemi
  static final Map<String, HijriDate> _hijriCache = {};

  /// Önbellekli Hijri tarih hesaplama
  static Future<HijriDate?> getCachedHijriDate(DateTime gregorianDate) async {
    final dateKey = '${gregorianDate.year}-${gregorianDate.month}-${gregorianDate.day}';
    
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
      // AlAdhan API'den doğru Hijri tarihi al
      final hijriDate = await getCachedHijriDate(now);
      if (hijriDate != null) {
        // İçeriğin Hijri tarihini güncelle (eğer model destekliyorsa)
        print('Bugünün Hijri tarihi: ${hijriDate.formattedDate}');
      }
    }
    
    return content;
  }
}
