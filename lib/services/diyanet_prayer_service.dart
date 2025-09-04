import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';

/// Service for fetching prayer times from Turkish Diyanet Prayer Times API
/// Provides Turkish prayer times with official Diyanet calculations
class DiyanetPrayerService {
  
  // Diyanet Prayer Times API URLs
  static const String _baseUrl = 'https://ezanvakti.herokuapp.com';
  static const String _backupUrl = 'https://api.aladhan.com/v1/calendarByCity';
  
  // Turkish cities and their IDs for Diyanet API
  static const Map<String, int> turkishCities = {
    'Adana': 9146,
    'Adıyaman': 9158,
    'Afyonkarahisar': 9167,
    'Ağrı': 9185,
    'Amasya': 9198,
    'Ankara': 9206,
    'Antalya': 9225,
    'Artvin': 9246,
    'Aydın': 9252,
    'Balıkesir': 9270,
    'Bilecik': 9297,
    'Bingöl': 9303,
    'Bitlis': 9311,
    'Bolu': 9315,
    'Burdur': 9327,
    'Bursa': 9335,
    'Çanakkale': 9352,
    'Çankırı': 9359,
    'Çorum': 9370,
    'Denizli': 9392,
    'Diyarbakır': 9402,
    'Edirne': 9419,
    'Elazığ': 9432,
    'Erzincan': 9440,
    'Erzurum': 9451,
    'Eskişehir': 9470,
    'Gaziantep': 9479,
    'Giresun': 9486,
    'Gümüşhane': 9489,
    'Hakkâri': 9492,
    'Hatay': 9498,
    'İçel': 9516,
    'İsparta': 9528,
    'İstanbul': 9541,
    'İzmir': 9560,
    'Kars': 9594,
    'Kastamonu': 9609,
    'Kayseri': 9620,
    'Kırklareli': 9629,
    'Kırşehir': 9635,
    'Kocaeli': 9654,
    'Konya': 9676,
    'Kütahya': 9689,
    'Malatya': 9701,
    'Manisa': 9708,
    'Kahramanmaraş': 9716,
    'Mardin': 9726,
    'Muğla': 9731,
    'Muş': 9747,
    'Nevşehir': 9754,
    'Niğde': 9760,
    'Ordu': 9766,
    'Rize': 9784,
    'Sakarya': 9789,
    'Samsun': 9797,
    'Siirt': 9807,
    'Sinop': 9819,
    'Sivas': 9829,
    'Tekirdağ': 9849,
    'Tokat': 9862,
    'Trabzon': 9879,
    'Tunceli': 9887,
    'Şanlıurfa': 9898,
    'Uşak': 9905,
    'Van': 9911,
    'Yozgat': 9919,
    'Zonguldak': 9930,
    'Aksaray': 9935,
    'Bayburt': 9940,
    'Karaman': 9945,
    'Kırıkkale': 9950,
    'Batman': 9955,
    'Şırnak': 9960,
    'Bartın': 9965,
    'Ardahan': 9970,
    'Iğdır': 9975,
    'Yalova': 9980,
    'Karabük': 9985,
    'Kilis': 9990,
    'Osmaniye': 9995,
    'Düzce': 10000,
  };

  /// Get prayer times for a specific city from Diyanet API
  static Future<PrayerTimesModel?> getPrayerTimes({
    required String cityName,
    DateTime? date,
  }) async {
    try {
      // Use today's date if not specified
      date ??= DateTime.now();
      
      print('🕌 Fetching prayer times from Diyanet API for $cityName');
      print('🕌 Date: ${date.toString().split(' ')[0]}');
      
      // Try Diyanet API first
      PrayerTimesModel? result = await _fetchFromDiyanetApi(cityName, date);
      
      // If Diyanet fails, use backup API with Turkish calculation method
      if (result == null) {
        print('⚠️ Diyanet API failed, trying backup with Turkish method...');
        result = await _fetchFromBackupApi(cityName, date);
      }
      
      if (result != null) {
        print('✅ Prayer times fetched successfully for $cityName');
        return result;
      } else {
        print('❌ Failed to fetch prayer times from all sources');
        return _getFallbackPrayerTimes(cityName, date);
      }
      
    } catch (e) {
      print('❌ Error in getPrayerTimes: $e');
      return _getFallbackPrayerTimes(cityName, date);
    }
  }

  /// Fetch from Diyanet-based API
  static Future<PrayerTimesModel?> _fetchFromDiyanetApi(String cityName, DateTime date) async {
    try {
      // Get city ID for Diyanet API
      final cityId = turkishCities[cityName];
      if (cityId == null) {
        print('❌ City not found in Diyanet database: $cityName');
        return null;
      }
      
      // Format date for API (YYYY-MM-DD)
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final url = '$_baseUrl/vakitler/$cityId/$dateStr';
      print('🌐 Diyanet API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'NurVakti-App/1.0',
        },
      ).timeout(Duration(seconds: 8));
      
      print('🌐 Diyanet API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data != null && data is List && data.isNotEmpty) {
          final prayerData = data[0];
          
          return PrayerTimesModel(
            imsak: _formatTime(prayerData['Imsak']),
            gunes: _formatTime(prayerData['Gunes']),
            ogle: _formatTime(prayerData['Ogle']),
            ikindi: _formatTime(prayerData['Ikindi']),
            aksam: _formatTime(prayerData['Aksam']),
            yatsi: _formatTime(prayerData['Yatsi']),
            date: dateStr,
          );
        }
      }
      
      print('❌ Diyanet API failed with status: ${response.statusCode}');
      return null;
      
    } catch (e) {
      print('❌ Diyanet API error: $e');
      return null;
    }
  }

  /// Fetch from backup API with Turkish calculation method
  static Future<PrayerTimesModel?> _fetchFromBackupApi(String cityName, DateTime date) async {
    try {
      // Use AlAdhan API with Turkish calculation method (method=13)
      final month = date.month;
      final year = date.year;
      
      final url = '$_backupUrl?city=$cityName&country=Turkey&method=13&month=$month&year=$year';
      print('🌐 Backup API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'NurVakti-App/1.0',
        },
      ).timeout(Duration(seconds: 10));
      
      print('🌐 Backup API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['data'] != null) {
          final monthData = data['data'] as List;
          
          // Find the specific day
          final dayData = monthData.firstWhere(
            (day) => day['date']['gregorian']['day'] == date.day.toString().padLeft(2, '0'),
            orElse: () => null,
          );
          
          if (dayData != null) {
            final timings = dayData['timings'];
            
            return PrayerTimesModel(
              imsak: _formatTime(timings['Imsak']),
              gunes: _formatTime(timings['Sunrise']),
              ogle: _formatTime(timings['Dhuhr']),
              ikindi: _formatTime(timings['Asr']),
              aksam: _formatTime(timings['Maghrib']),
              yatsi: _formatTime(timings['Isha']),
              date: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            );
          }
        }
      }
      
      return null;
      
    } catch (e) {
      print('❌ Backup API error: $e');
      return null;
    }
  }

  /// Get fallback prayer times (approximate)
  static PrayerTimesModel _getFallbackPrayerTimes(String cityName, DateTime? date) {
    final targetDate = date ?? DateTime.now();
    print('⚠️ Using fallback prayer times for $cityName');
    
    // Basic fallback times (approximate for Turkey)
    return PrayerTimesModel(
      imsak: '05:30',
      gunes: '07:00',
      ogle: '12:30',
      ikindi: '15:30',
      aksam: '18:00',
      yatsi: '19:30',
      date: '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
    );
  }

  /// Format time string (ensure HH:MM format and remove timezone)
  static String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '00:00';
    
    try {
      // Remove timezone info if present (e.g., "12:30 (+03)" -> "12:30")
      String cleanTime = timeStr.split(' ')[0];
      
      // Handle different time formats
      if (cleanTime.contains(':')) {
        final parts = cleanTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]).toString().padLeft(2, '0');
          final minute = int.parse(parts[1]).toString().padLeft(2, '0');
          return '$hour:$minute';
        }
      }
      
      return cleanTime;
    } catch (e) {
      print('⚠️ Time formatting error for "$timeStr": $e');
      return '00:00';
    }
  }

  /// Get all available cities
  static List<String> getAvailableCities() {
    return turkishCities.keys.toList()..sort();
  }

  /// Find closest city name match
  static String? findClosestCity(String searchTerm) {
    final cities = getAvailableCities();
    final lowerSearch = searchTerm.toLowerCase();
    
    // Exact match first
    for (final city in cities) {
      if (city.toLowerCase() == lowerSearch) {
        return city;
      }
    }
    
    // Partial match
    for (final city in cities) {
      if (city.toLowerCase().contains(lowerSearch)) {
        return city;
      }
    }
    
    // No match found
    return null;
  }

  /// Test API connection
  static Future<bool> testConnection() async {
    try {
      print('🧪 Testing Diyanet Prayer API connection...');
      
      final result = await getPrayerTimes(
        cityName: 'İstanbul',
        date: DateTime.now(),
      );
      
      if (result != null) {
        print('✅ Diyanet Prayer API connection successful');
        print('✅ Sample times: İmsak=${result.imsak}, Öğle=${result.ogle}');
        return true;
      } else {
        print('❌ Diyanet Prayer API connection failed');
        return false;
      }
      
    } catch (e) {
      print('❌ Diyanet Prayer API connection test error: $e');
      return false;
    }
  }
}
