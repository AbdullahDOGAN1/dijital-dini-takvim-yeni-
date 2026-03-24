// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/religious_event_model.dart';
import 'diyanet_json_cache_service.dart';

class ReligiousEventsService {
  static final List<ReligiousEvent> _allEvents = [];
  static final List<ReligiousEventDetails> _eventDetails = [];
  static bool _isLoaded = false;
  static int? _loadedYear; // Hangi yıl için yüklendiğini takip et
  static final DiyanetJsonCacheService _jsonCacheService =
      DiyanetJsonCacheService();

  /// Yıl değiştiğinde cache'i otomatik temizle
  static void _checkYearChange() {
    final currentYear = DateTime.now().year;
    if (_loadedYear != null && _loadedYear != currentYear) {
      print(
        '🔄 Year changed from $_loadedYear to $currentYear, clearing cache',
      );
      clearCache();
    }
  }

  /// Tüm dini günleri yükle (dinamik yıl sistemi)
  /// Önce JSON cache'den dener, başarısız olursa bundle JSON dosyasından okur
  static Future<void> loadReligiousEvents() async {
    // Yıl değişikliğini kontrol et
    _checkYearChange();

    if (_isLoaded) return;

    try {
      // Önce uzaktaki JSON cache'den dene
      final currentYear = DateTime.now().year;
      final nextYear = currentYear + 1;

      bool loadedFromCache = false;

      try {
        final currentYearData = await _jsonCacheService.getCachedReligiousDays(
          year: currentYear,
        );
        final nextYearData = await _jsonCacheService.getCachedReligiousDays(
          year: nextYear,
        );

        if (currentYearData != null && currentYearData.isNotEmpty) {
          _allEvents.clear();

          // JSON cache response'unu ReligiousEvent'e çevir
          for (final eventData in currentYearData) {
            final event = _convertDiyanetApiToReligiousEvent(
              eventData,
              currentYear,
            );
            if (event != null) {
              _allEvents.add(event);
            }
          }

          if (nextYearData != null && nextYearData.isNotEmpty) {
            for (final eventData in nextYearData) {
              final event = _convertDiyanetApiToReligiousEvent(
                eventData,
                nextYear,
              );
              if (event != null) {
                _allEvents.add(event);
              }
            }
          }

          if (_allEvents.isNotEmpty) {
            loadedFromCache = true;
            _loadedYear = currentYear;
            _isLoaded = true;

            if (kDebugMode) {
              print(
                '✅ Dini günler JSON cache\'den yüklendi: ${_allEvents.length} etkinlik',
              );
            }

            // Detayları JSON'dan yükle (API'de detay yok)
            await _loadEventDetailsFromJson();
            return;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '⚠️ JSON cache başarısız, bundle JSON dosyasından okunuyor: $e',
          );
        }
      }

      // Fallback: bundle JSON dosyasından oku
      if (!loadedFromCache) {
        // Tarih verilerini yükle
        final datesData = await rootBundle.loadString(
          'assets/data/dinigünlertarih.json',
        );
        final datesJson = json.decode(datesData) as Map<String, dynamic>;

        _allEvents.clear();

        // Mevcut yıl ve sonraki yılı yükle
        final currentYear = DateTime.now().year;
        final nextYear = currentYear + 1;
        final currentYearStr = currentYear.toString();
        final nextYearStr = nextYear.toString();
        _loadedYear = currentYear; // Yüklenen yılı kaydet

        if (kDebugMode) {
          print(
            '🗓️ Loading religious events for $currentYearStr and $nextYearStr',
          );
        }

        // Mevcut yıl verilerini yükle
        final eventsCurrentYear = datesJson[currentYearStr] as List<dynamic>?;
        if (eventsCurrentYear != null) {
          for (final eventJson in eventsCurrentYear) {
            final event = ReligiousEvent.fromJson(eventJson, currentYearStr);
            _allEvents.add(event);
          }
          if (kDebugMode) {
            print(
              '📅 Loaded ${eventsCurrentYear.length} events for $currentYearStr',
            );
          }
        }

        // Sonraki yıl verilerini yükle (yaklaşan günler için)
        final eventsNextYear = datesJson[nextYearStr] as List<dynamic>?;
        if (eventsNextYear != null) {
          for (final eventJson in eventsNextYear) {
            final event = ReligiousEvent.fromJson(eventJson, nextYearStr);
            _allEvents.add(event);
          }
          if (kDebugMode) {
            print('📅 Loaded ${eventsNextYear.length} events for $nextYearStr');
          }
        }

        // Detay verilerini yükle (sadece boşsa)
        await _loadEventDetailsFromJson();
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
      final currentYearStr = DateTime.now().year.toString();
      final nextYearStr = (DateTime.now().year + 1).toString();
      print(
        '🗓️ Total loaded: ${_allEvents.length} religious events for $currentYearStr & $nextYearStr',
      );
      print(
        '📅 Date range: ${_allEvents.first.parsedDate} → ${_allEvents.last.parsedDate}',
      );
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

    return _allEvents
        .where((event) {
          // Hicri tarihi miladi tarihe çevir
          final gregorianDate = _convertToGregorian(event.parsedDate);
          if (gregorianDate == null) return false;

          // Bugünden sonraki 60 gün içindeki etkinlikler (mevcut ve gelecek yıl)
          return gregorianDate.isAfter(now) &&
              gregorianDate.isBefore(futureLimit) &&
              (event.parsedDate.year >= currentYear &&
                  event.parsedDate.year <= nextYear);
        })
        .take(20)
        .toList(); // İlk 20 yaklaşan etkinlik
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
        event.parsedDate.day,
      );
      return eventDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  /// Kategoriye göre dini günleri getir
  static List<ReligiousEvent> getEventsByCategory(String category) {
    return _allEvents.where((event) => event.category == category).toList();
  }

  /// Belirli yıla ait dini günleri getir
  static List<ReligiousEvent> getEventsForYear(int year) {
    return _allEvents.where((event) => event.parsedDate.year == year).toList();
  }

  /// Mevcut yılın tüm dini günlerini getir
  static List<ReligiousEvent> getCurrentYearEvents() {
    final currentYear = DateTime.now().year;
    final upcomingEvents = getUpcomingEvents(days: 365);

    return _allEvents
        .where(
          (event) =>
              event.parsedDate.year == currentYear ||
              upcomingEvents.contains(event),
        )
        .toList();
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
      return event.parsedDate.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          event.parsedDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  /// Bu ayki dini günleri getir
  static List<ReligiousEvent> getThisMonthEvents() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    return _allEvents.where((event) {
      return event.parsedDate.isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ) &&
          event.parsedDate.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  /// Event detaylarını getir
  static ReligiousEventDetails? getEventDetails(String eventName) {
    // DOĞRUDAN MAPPING - En problemli isimleri direkt eşle
    Map<String, String> directMapping = {
      'RAMAZAN BAY. AREFESİ': 'Ramazan Bayramı Arefesi',
      'KURBAN BAY. AREFESİ': 'Kurban Bayramı Arefesi',
      'REGAİB KANDİLİ': 'Regaib Kandili',
      'MİRAC KANDİLİ': 'Mirac Kandili',
      'BERAT KANDİLİ': 'Berat Kandili',
      'KADİR GECESİ': 'Kadir Gecesi',
      'MEVLİD KANDİLİ': 'Mevlid Kandili',
      'ÜÇ AYLARIN BAŞLANGICI': 'Üç Ayların Başlangıcı',
      'RAMAZAN BAŞLANGICI': 'Ramazan Başlangıcı',
      'HİCRİ YILBAŞI': 'Hicri Yılbaşı',
      'AŞURE GÜNÜ': 'Aşure Günü',
      'RAMAZAN BAYRAMI': 'Ramazan Bayramı',
      'KURBAN BAYRAMI': 'Kurban Bayramı',
      // Bayram günleri (X. GÜN) formatı
      'RAMAZAN BAYRAMI (1. GÜN)': 'Ramazan Bayramı',
      'RAMAZAN BAYRAMI (2. GÜN)': 'Ramazan Bayramı',
      'RAMAZAN BAYRAMI (3. GÜN)': 'Ramazan Bayramı',
      'KURBAN BAYRAMI (1. GÜN)': 'Kurban Bayramı',
      'KURBAN BAYRAMI (2. GÜN)': 'Kurban Bayramı',
      'KURBAN BAYRAMI (3. GÜN)': 'Kurban Bayramı',
      'KURBAN BAYRAMI (4. GÜN)': 'Kurban Bayramı',
    };

    print('🔍 Looking for event details: "$eventName"');
    print('🔍 Total _eventDetails count: ${_eventDetails.length}');
    print(
      '🔍 First 3 details: ${_eventDetails.take(3).map((d) => d.name).toList()}',
    );

    // Önce direkt mapping dene (NORMALIZATION YOK!)
    String? mappedName = directMapping[eventName];
    if (mappedName != null) {
      print('   🔄 DIRECT MAPPING: "$eventName" -> "$mappedName"');

      // Bu mapped name ile EXACT match ara (normalization YOK!)
      print('   🔍 Available details count: ${_eventDetails.length}');
      for (final detail in _eventDetails) {
        print(
          '   📋 EXACT CHECK: "${detail.name}" == "$mappedName" -> ${detail.name == mappedName}',
        );

        if (detail.name == mappedName) {
          print('   ✅ DIRECT EXACT MATCH found for: $eventName');
          return detail;
        }
      }
      print(
        '   ⚠️ Direct mapping buldu ama exact detay bulunamadı: "$mappedName"',
      );
    }

    // Direkt mapping başarısızsa normalizasyon ile dene
    final normalizedName = _normalizeEventName(eventName);
    print('   🔧 Normalized search: "$eventName" -> "$normalizedName"');

    for (final detail in _eventDetails) {
      final detailName = _normalizeEventName(detail.name);
      print(
        '   📋 Checking against: "${detail.name}" -> normalized: "$detailName"',
      );

      if (detailName == normalizedName) {
        print('   ✅ EXACT MATCH found for: $eventName');
        return detail;
      } else if (detailName.contains(normalizedName) ||
          normalizedName.contains(detailName)) {
        print('   ✅ PARTIAL MATCH found for: $eventName');
        return detail;
      }
    }

    print('   ❌ NO MATCH found for: $eventName');
    print('   📝 Available details:');
    for (final detail in _eventDetails) {
      print('      - "${detail.name}"');
    }
    return null;
  }

  /// Event isimlerini normalize et ve eşleştir
  static String _normalizeEventName(String name) {
    // Önce büyük/küçük harf dönüşümü ve Türkçe karakter normalize etme
    String normalized = name
        .toLowerCase()
        .replaceAll('i̇', 'i')
        // "bayram" kelimesini normalize et (hem "bay." hem "bayrami" -> "bayram")
        .replaceAll('bay.', 'bayram')
        .replaceAll('bay ', 'bayram ')
        .replaceAll('bayrami', 'bayram') // "bayrami" -> "bayram"
        .replaceAll('bayramı', 'bayram') // "bayramı" -> "bayram"
        .replaceAll(
          'ı',
          '',
        ) // ı karakterini tamamen çıkar (detail dosyasındaki gibi)
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // İsim eşleştirme tablosu - debug loglarından elde edilen problemli durumlar için
    Map<String, String> nameMapping = {
      // Debug loglarından kesin mapping'ler:
      'uc aylarin baslangici':
          'uc aylarn baslangc', // Map to detail file format
      'ramazan baslangici': 'ramazan baslangc', // Map to detail file format
      'hicri yilbasi': 'hicri ylbas', // Map to detail file format
      // Exact matches needed:
      'uc aylarn baslangc': 'uc aylarn baslangc', // Match detail file exactly
      'ramazan baslangc': 'ramazan baslangc', // Match detail file exactly
      'hcr ylbas': 'hicri ylbas', // Match detail file exactly
      // Arefe mappings - updated with new names
      'ramazan bay arefs': 'ramazan bayram arefesi',
      'kurban bay arefs': 'kurban bayram arefesi',
      'ramazan bay arefes': 'ramazan bayram arefesi',
      'kurban bay arefes': 'kurban bayram arefesi',
      'ramazan bay arefesi': 'ramazan bayram arefesi',
      'kurban bay arefesi': 'kurban bayram arefesi',
      'ramazan bayram arefs': 'ramazan bayram arefesi',
      'kurban bayram arefs': 'kurban bayram arefesi',
      'ramazan bayram arefes': 'ramazan bayram arefesi',
      'kurban bayram arefes': 'kurban bayram arefesi',
      // Exact mappings for consistency
      'regab kandl': 'regaib kandili',
      'mrac kandl': 'mirac kandili',
      'berat kandl': 'berat kandili',
      'kadr geces': 'kadir gecesi',
      'ramazan bayram': 'ramazan bayram',
      'kurban bayram': 'kurban bayram',
      'asure gunu': 'asure gunu',
      'mevld kandl': 'mevlid kandili',
    };

    // Eğer eşleştirme tablosunda varsa o değeri döndür
    return nameMapping[normalized] ?? normalized;
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
      return DateTime(gregorianYear, hijriDate.month, hijriDate.day);
    } catch (e) {
      print('Error converting to Gregorian: $e');
      return null;
    }
  }

  /// Diyanet API response'unu ReligiousEvent'e çevir
  static ReligiousEvent? _convertDiyanetApiToReligiousEvent(
    Map<String, dynamic> apiData,
    int year,
  ) {
    try {
      // Diyanet API response formatını kontrol et ve parse et
      // API response formatı: {name, hijriDate, gregorianDate, ...}
      final name = apiData['name'] ?? apiData['eventName'] ?? '';
      final hijriDate = apiData['hijriDate'] ?? apiData['hijriDateShort'] ?? '';
      final gregorianDate =
          apiData['gregorianDate'] ?? apiData['gregorianDateShort'] ?? '';

      if (name.isEmpty) return null;

      // Gregorian tarihi parse et
      DateTime parsedDate;
      try {
        if (gregorianDate.contains('-')) {
          // YYYY-MM-DD formatı
          final parts = gregorianDate.split('-');
          parsedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else if (gregorianDate.contains('.')) {
          // DD.MM.YYYY formatı
          final parts = gregorianDate.split('.');
          parsedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } else {
          parsedDate = DateTime.now();
        }
      } catch (e) {
        parsedDate = DateTime.now();
      }

      return ReligiousEvent(
        name: name,
        hijriDate: hijriDate,
        gregorianDate: gregorianDate,
        dayOfWeek: _getDayOfWeekName(parsedDate.weekday),
        year: year.toString(),
        parsedDate: parsedDate,
        category: _categorizeEvent(name),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error converting Diyanet API data: $e');
      }
      return null;
    }
  }

  /// Haftanın günü ismini getir
  static String _getDayOfWeekName(int weekday) {
    const days = [
      'Pazar',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
    ];
    return days[weekday % 7];
  }

  /// Event'i kategorize et
  static String _categorizeEvent(String eventName) {
    final name = eventName.toLowerCase();
    if (name.contains('kandil')) return 'kandil';
    if (name.contains('bayram')) return 'bayram';
    if (name.contains('hac') || name.contains('hajj')) return 'hac';
    if (name.contains('arefe')) return 'ozel_gun';
    return 'diger';
  }

  /// Event detaylarını JSON'dan yükle
  static Future<void> _loadEventDetailsFromJson() async {
    if (_eventDetails.isNotEmpty) return;

    if (kDebugMode) {
      print('🔄 Starting to load event details...');
    }
    try {
      if (kDebugMode) {
        print('📁 Attempting to load: assets/data/yeni_veri_detay.json');
      }
      final detailsData = await rootBundle.loadString(
        'assets/data/yeni_veri_detay.json',
      );
      if (kDebugMode) {
        print('✅ JSON file loaded successfully, length: ${detailsData.length}');
      }
      final detailsList = json.decode(detailsData) as List<dynamic>;
      if (kDebugMode) {
        print('✅ JSON parsed successfully, items count: ${detailsList.length}');
      }

      // Detayları parse et
      for (final detailJson in detailsList) {
        final detail = ReligiousEventDetails.fromJson(detailJson);
        _eventDetails.add(detail);
        if (kDebugMode) {
          print(
            '📋 Loaded detail for: "${detail.name}" -> normalized: "${_normalizeEventName(detail.name)}"',
          );
        }
      }
      if (kDebugMode) {
        print('✅ Event details loaded: ${_eventDetails.length} events');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '⚠️ Warning: Could not load new event details from assets/data/yeni_veri_detay.json: $e',
        );
      }
      // Fallback: eski format dene
      try {
        final fallbackData = await rootBundle.loadString(
          'assets/data/dinigünler_açıklama.json',
        );
        final fallbackList = json.decode(fallbackData) as List<dynamic>;

        for (final detailJson in fallbackList) {
          final detail = ReligiousEventDetails.fromJson(detailJson);
          _eventDetails.add(detail);
        }
        if (kDebugMode) {
          print('✅ Fallback event details loaded: ${_eventDetails.length}');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ Could not load any event details: $fallbackError');
        }
        _eventDetails.clear();
      }
    }
  }

  /// Debug için tüm etkinlikleri yazdır
  static void printAllEvents() {
    if (kDebugMode) {
      print('=== TÜM DİNİ GÜNLER ===');
      for (final event in _allEvents) {
        print('${event.name} - ${event.gregorianDate} (${event.category})');
      }
    }
  }
}
