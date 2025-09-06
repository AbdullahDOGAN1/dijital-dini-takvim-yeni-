import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/religious_event_model.dart';

class ReligiousEventsService {
  static List<ReligiousEvent> _allEvents = [];
  static List<ReligiousEventDetails> _eventDetails = [];
  static bool _isLoaded = false;
  static int? _loadedYear; // Hangi yıl için yüklendiğini takip et

  /// Yıl değiştiğinde cache'i otomatik temizle
  static void _checkYearChange() {
    final currentYear = DateTime.now().year;
    if (_loadedYear != null && _loadedYear != currentYear) {
      print('🔄 Year changed from $_loadedYear to $currentYear, clearing cache');
      clearCache();
    }
  }

  /// Tüm dini günleri yükle (dinamik yıl sistemi)
  static Future<void> loadReligiousEvents() async {
    // Yıl değişikliğini kontrol et
    _checkYearChange();
    
    if (_isLoaded) return;

    try {
      // Tarih verilerini yükle
      final datesData = await rootBundle.loadString('assets/data/dinigünlertarih.json');
      final datesJson = json.decode(datesData) as Map<String, dynamic>;
      
      _allEvents.clear();
      _eventDetails.clear();

      // Mevcut yıl ve sonraki yılı yükle
      final currentYear = DateTime.now().year;
      final nextYear = currentYear + 1;
      final currentYearStr = currentYear.toString();
      final nextYearStr = nextYear.toString();
      _loadedYear = currentYear; // Yüklenen yılı kaydet
      
      print('🗓️ Loading religious events for $currentYearStr and $nextYearStr');
      
      // Mevcut yıl verilerini yükle
      final eventsCurrentYear = datesJson[currentYearStr] as List<dynamic>?;
      if (eventsCurrentYear != null) {
        for (final eventJson in eventsCurrentYear) {
          final event = ReligiousEvent.fromJson(eventJson, currentYearStr);
          _allEvents.add(event);
        }
        print('📅 Loaded ${eventsCurrentYear.length} events for $currentYearStr');
      }
      
      // Sonraki yıl verilerini yükle (yaklaşan günler için)
      final eventsNextYear = datesJson[nextYearStr] as List<dynamic>?;
      if (eventsNextYear != null) {
        for (final eventJson in eventsNextYear) {
          final event = ReligiousEvent.fromJson(eventJson, nextYearStr);
          _allEvents.add(event);
        }
        print('📅 Loaded ${eventsNextYear.length} events for $nextYearStr');
      }

      // Detay verilerini yükle  
      try {
        final detailsData = await rootBundle.loadString('assets/data/dinigünler_açıklama.json');
        final detailsList = json.decode(detailsData) as List<dynamic>;
        
        // Detayları parse et
        for (final detailJson in detailsList) {
          final detail = ReligiousEventDetails.fromJson(detailJson);
          _eventDetails.add(detail);
        }
        print('✅ Event details loaded: ${_eventDetails.length}');
      } catch (e) {
        print('⚠️ Warning: Could not load event details: $e');
        _eventDetails.clear();
      }

      // Tarihe göre sırala (miladi tarihe göre kronolojik)
      _allEvents.sort((a, b) {
        // Miladi tarihe çevir ve karşılaştır
        final gregorianA = _convertToGregorian(a.parsedDate);
        final gregorianB = _convertToGregorian(b.parsedDate);
        
        if (gregorianA == null || gregorianB == null) {
          return a.parsedDate.compareTo(b.parsedDate);
        }
        
        final dateComparison = gregorianA.compareTo(gregorianB);
        if (dateComparison != 0) return dateComparison;
        
        // Aynı tarihte ise isim alfabetik sıraya göre
        return a.name.compareTo(b.name);
      });

      _isLoaded = true;
      print('🗓️ Total loaded: ${_allEvents.length} religious events for $currentYearStr & $nextYearStr');
      print('📅 Date range: ${_allEvents.first.parsedDate} → ${_allEvents.last.parsedDate}');
      
    } catch (e) {
      print('❌ Error loading religious events: $e');
      throw Exception('Dini günler yüklenirken hata oluştu: $e');
    }
  }

  /// Yaklaşan dini günleri getir (mevcut ve gelecek yıl dahil - 60 gün sınırı)
  static List<ReligiousEvent> getUpcomingEvents({int days = 60}) {
    final now = DateTime.now();
    final currentYear = now.year;
    final nextYear = currentYear + 1;
    final futureLimit = now.add(Duration(days: days)); // 60 günlük sınır
    
    return _allEvents.where((event) {
      // Hicri tarihi miladi tarihe çevir
      final gregorianDate = _convertToGregorian(event.parsedDate);
      if (gregorianDate == null) return false;
      
      // Bugünden sonraki 60 gün içindeki etkinlikler (mevcut ve gelecek yıl)
      return gregorianDate.isAfter(now) && 
             gregorianDate.isBefore(futureLimit) &&
             (event.parsedDate.year >= currentYear && event.parsedDate.year <= nextYear);
    }).take(20).toList(); // İlk 20 yaklaşan etkinlik
  }

  /// Bugünün dini günlerini getir
  static List<ReligiousEvent> getTodaysEvents() {
    return _allEvents.where((event) => event.isToday).toList();
  }

  /// Belirli bir tarihteki dini günleri getir
  static List<ReligiousEvent> getEventsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return _allEvents.where((event) {
      final eventDate = DateTime(
        event.parsedDate.year, 
        event.parsedDate.month, 
        event.parsedDate.day
      );
      return eventDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  /// Kategoriye göre dini günleri getir
  static List<ReligiousEvent> getEventsByCategory(String category) {
    return _allEvents.where((event) => (event.category ?? 'diger') == category).toList();
  }

  /// Belirli yıla ait dini günleri getir
  static List<ReligiousEvent> getEventsForYear(int year) {
    return _allEvents.where((event) => 
      event.parsedDate.year == year
    ).toList();
  }

  /// Mevcut yılın tüm dini günlerini getir
  static List<ReligiousEvent> getCurrentYearEvents() {
    final currentYear = DateTime.now().year;
    final upcomingEvents = getUpcomingEvents(days: 365);
    
    return _allEvents.where((event) => 
      event.parsedDate.year == currentYear ||
      upcomingEvents.contains(event)
    ).toList();
  }

  /// Bir sonraki yaklaşan dini günü getir
  static ReligiousEvent? getNextUpcomingEvent() {
    final upcoming = getUpcomingEvents(days: 365);
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Bu haftaki dini günleri getir
  static List<ReligiousEvent> getThisWeekEvents() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return _allEvents.where((event) {
      return event.parsedDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             event.parsedDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  /// Bu ayki dini günleri getir
  static List<ReligiousEvent> getThisMonthEvents() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    
    return _allEvents.where((event) {
      return event.parsedDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
             event.parsedDate.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  /// Event detaylarını getir
  static ReligiousEventDetails? getEventDetails(String eventName) {
    final normalizedName = _normalizeEventName(eventName);
    
    for (final detail in _eventDetails) {
      final detailName = _normalizeEventName(detail.name);
      if (detailName.contains(normalizedName) || normalizedName.contains(detailName)) {
        return detail;
      }
    }
    
    return null;
  }

  /// Event isimlerini normalize et
  static String _normalizeEventName(String name) {
    return name
        .toLowerCase()
        .replaceAll('i̇', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Event istatistiklerini getir
  static Map<String, int> getEventStatistics() {
    final Map<String, int> stats = {};
    
    for (final event in _allEvents) {
      final category = event.category ?? 'diger';
      stats[category] = (stats[category] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Kategori renklerini getir
  static Map<String, String> getCategoryColors() {
    return {
      'kandil': '#FFD700',
      'bayram': '#FF6B6B',
      'ozel_gun': '#4ECDC4',
      'hac': '#45B7D1',
      'diger': '#96CEB4',
    };
  }

  /// Kategori ikonlarını getir
  static Map<String, String> getCategoryIcons() {
    return {
      'kandil': '🕌',
      'bayram': '🎉',
      'ozel_gun': '⭐',
      'hac': '🕋',
      'diger': '📖',
    };
  }

  /// Cache'i temizle
  static void clearCache() {
    _allEvents.clear();
    _eventDetails.clear();
    _isLoaded = false;
  }

  /// Hicri tarihi miladi tarihe çevir (yaklaşık)
  static DateTime? _convertToGregorian(DateTime hijriDate) {
    try {
      // Yaklaşık çeviri: Hicri yıl - 578.5 = Miladi yıl
      final gregorianYear = (hijriDate.year - 578.5).round();
      
      // Ay ve gün aynı kalır (yaklaşık hesaplama)
      return DateTime(
        gregorianYear, 
        hijriDate.month, 
        hijriDate.day
      );
    } catch (e) {
      print('Error converting to Gregorian: $e');
      return null;
    }
  }

  /// Tarih formatını kısalt
  static String _formatShortDate(String fullDate) {
    try {
      // "01 OCAK-2025" -> "01/OCAK" formatına çevir
      if (fullDate.contains('-')) {
        final parts = fullDate.split('-');
        return parts[0]; // Sadece gün ve ay kısmını al
      }
      return fullDate;
    } catch (e) {
      return fullDate;
    }
  }

  /// Debug için tüm etkinlikleri yazdır
  static void printAllEvents() {
    print('=== TÜM DİNİ GÜNLER ===');
    for (final event in _allEvents) {
      print('${event.name} - ${event.gregorianDate} (${event.category})');
    }
  }
}
