import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/religious_day_model.dart';

class DiyanetApiService {
  static const String _baseUrl = 'https://www.diyanet.gov.tr';
  
  /// Diyanet'in API'sinden dini günleri çek
  /// Bu endpoint değişebilir, güncel olduğundan emin olun
  Future<List<ReligiousDay>> fetchReligiousDaysFromDiyanet({
    int? year,
  }) async {
    final targetYear = year ?? DateTime.now().year;
    
    try {
      // Diyanet'in API endpoint'i - bu URL güncel olmalı
      final url = Uri.parse('$_baseUrl/api/dini-gunler/$targetYear');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'NurVakti-App/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List) {
          return data.map((item) => _convertDiyanetDataToReligiousDay(item)).toList();
        } else if (data is Map && data['data'] != null) {
          final List<dynamic> items = data['data'];
          return items.map((item) => _convertDiyanetDataToReligiousDay(item)).toList();
        }
      } else {
        print('Diyanet API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching from Diyanet API: $e');
    }
    
    // API başarısız olursa fallback data döndür
    return _getFallbackReligiousDays(targetYear);
  }

  /// Diyanet'ten gelen veriyi ReligiousDay modeline çevir
  ReligiousDay _convertDiyanetDataToReligiousDay(Map<String, dynamic> data) {
    // Diyanet API'den gelen alanları model'e uyarlayın
    return ReligiousDay(
      name: data['name'] ?? data['title'] ?? '',
      date: _parseDate(data['date'] ?? data['gregorian_date']),
      hijriDate: data['hijri_date'] ?? '',
      category: _determineCategory(data['name'] ?? data['title'] ?? ''),
      description: data['description'] ?? '',
      importance: data['importance'] ?? data['significance'] ?? '',
      traditions: _parseStringList(data['traditions']),
      prayers: _parseStringList(data['prayers']),
    );
  }

  /// Tarihi parse et
  DateTime _parseDate(dynamic dateData) {
    if (dateData is String) {
      try {
        // Farklı tarih formatlarını destekle
        if (dateData.contains('-')) {
          return DateTime.parse(dateData);
        } else if (dateData.contains('/')) {
          final parts = dateData.split('/');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[2]), // yıl
              int.parse(parts[1]), // ay
              int.parse(parts[0]), // gün
            );
          }
        }
      } catch (e) {
        print('Date parsing error: $e');
      }
    }
    
    return DateTime.now(); // Fallback
  }

  /// Kategoriyi belirle
  String _determineCategory(String name) {
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains('kandil')) {
      return 'kandil';
    } else if (lowerName.contains('bayram')) {
      return 'bayram';
    } else if (lowerName.contains('gece')) {
      return 'özel_gün';
    } else {
      return 'özel_gün';
    }
  }

  /// String listesini parse et
  List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    } else if (data is String) {
      return data.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }

  /// API başarısız olursa kullanılacak fallback data
  List<ReligiousDay> _getFallbackReligiousDays(int year) {
    // 2025 için bilinen tarihler
    if (year == 2025) {
      return [
        ReligiousDay(
          name: 'Regaib Kandili',
          date: DateTime(2025, 1, 3),
          hijriDate: '1 Recep 1446',
          category: 'kandil',
          description: 'Recep ayının ilk Cuma gecesi olan Regaib Kandili.',
          importance: 'Rahmetin bol olduğu mübarek gece.',
          traditions: ['Oruç tutma', 'Gece ibadeti', 'Kur\'an okuma'],
          prayers: ['Regaib namazı', 'Tesbih ve zikir'],
        ),
        ReligiousDay(
          name: 'Miraç Kandili',
          date: DateTime(2025, 1, 27),
          hijriDate: '27 Recep 1446',
          category: 'kandil',
          description: 'Hz. Muhammed\'in Miraç\'a çıktığı mübarek gece.',
          importance: 'Beş vakit namazın farz kılındığı gece.',
          traditions: ['Mirac hadisesi anlatılır', 'Gece ibadeti'],
          prayers: ['Gece namazı', 'Kur\'an okuma'],
        ),
        ReligiousDay(
          name: 'Berat Kandili',
          date: DateTime(2025, 2, 13),
          hijriDate: '15 Şaban 1446',
          category: 'kandil',
          description: 'Şaban ayının 15. gecesi olan Berat Kandili.',
          importance: 'Günahların affedildiği ve beraat bulunduğu gece.',
          traditions: ['Oruç tutma', 'Mezarlık ziyareti', 'Sadaka verme'],
          prayers: ['Berat namazı', 'İstiğfar'],
        ),
        ReligiousDay(
          name: 'Ramazan Başlangıcı',
          date: DateTime(2025, 2, 28),
          hijriDate: '1 Ramazan 1446',
          category: 'özel_gün',
          description: 'Mübarek Ramazan ayının başlangıcı.',
          importance: 'Oruç tutmanın farz kılındığı mübarek ay.',
          traditions: ['Oruç tutma', 'İftar', 'Sahur', 'Teravih'],
          prayers: ['Teravih namazı', 'Kur\'an okuma'],
        ),
        ReligiousDay(
          name: 'Kadir Gecesi',
          date: DateTime(2025, 3, 25),
          hijriDate: '27 Ramazan 1446',
          category: 'kandil',
          description: 'Kur\'an\'ın indirildiği mübarek gece.',
          importance: 'Bin aydan daha hayırlı olan gece.',
          traditions: ['Gece ibadeti', 'Kur\'an okuma', 'Dua etme'],
          prayers: ['Kadir gecesi namazı', 'Tesbih'],
        ),
        ReligiousDay(
          name: 'Ramazan Bayramı',
          date: DateTime(2025, 3, 30),
          hijriDate: '1 Şevval 1446',
          category: 'bayram',
          description: 'Ramazan orucunun tamamlanmasıyla kutlanan bayram.',
          importance: 'Müslümanların en büyük bayramlarından biri.',
          traditions: ['Bayram namazı', 'Ziyaretleşme', 'Bayramlık'],
          prayers: ['Bayram namazı', 'Takbir'],
        ),
        ReligiousDay(
          name: 'Kurban Bayramı',
          date: DateTime(2025, 6, 6),
          hijriDate: '10 Zilhicce 1446',
          category: 'bayram',
          description: 'Hz. İbrahim\'in kurban kesmeye hazır oluşunun anıldığı bayram.',
          importance: 'Hac ibadetinin tamamlandığı ve kurban kesildiği bayram.',
          traditions: ['Kurban kesme', 'Bayram namazı', 'Ziyaretleşme'],
          prayers: ['Bayram namazı', 'Takbir'],
        ),
      ];
    }
    
    return [];
  }

  /// Gelecek dini güne kadar kalan süreyi hesapla
  Future<Map<String, dynamic>?> getNextReligiousDay() async {
    final religiousDays = await fetchReligiousDaysFromDiyanet();
    final now = DateTime.now();
    
    // Gelecekteki ilk dini günü bul
    final upcomingDays = religiousDays.where((day) => day.date.isAfter(now)).toList();
    
    if (upcomingDays.isNotEmpty) {
      upcomingDays.sort((a, b) => a.date.compareTo(b.date));
      final nextDay = upcomingDays.first;
      
      final difference = nextDay.date.difference(now);
      
      return {
        'religiousDay': nextDay,
        'daysRemaining': difference.inDays,
        'hoursRemaining': difference.inHours % 24,
        'minutesRemaining': difference.inMinutes % 60,
      };
    }
    
    return null;
  }

  /// Bu yılın kalan dini günlerini getir
  Future<List<ReligiousDay>> getUpcomingReligiousDays() async {
    final religiousDays = await fetchReligiousDaysFromDiyanet();
    final now = DateTime.now();
    
    return religiousDays.where((day) => day.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Belirli bir kategorideki dini günleri getir
  Future<List<ReligiousDay>> getReligiousDaysByCategory(String category) async {
    final religiousDays = await fetchReligiousDaysFromDiyanet();
    return religiousDays.where((day) => day.category == category).toList();
  }
}
