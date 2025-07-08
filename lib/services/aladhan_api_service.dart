import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';

class AlAdhanApiService {
  static const String _baseUrl = 'http://api.aladhan.com/v1';
  
  /// Türkiye için varsayılan koordinatlar (Ankara)
  static const double _defaultLatitude = 39.9334;
  static const double _defaultLongitude = 32.8597;
  
  /// Diyanet İşleri hesaplama yöntemi - Türkiye resmi hesaplama
  /// Method 13: Türkiye Diyanet İşleri Başkanlığı
  /// Bu method Türkiye'nin resmi namaz vakitleri hesaplama standardıdır
  static const int _calculationMethod = 13;
  
  /// Türkiye zaman dilimi
  static const String _timeZone = 'Europe/Istanbul';
  
  /// Diyanet ile tam uyumlu tune parametreleri (dakika cinsinden ayarlamalar)
  /// Bu değerler Türkiye Diyanet İşleri'nin resmi vakitleri ile senkronize edilmiştir
  /// Sıra: Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha, Imsak, Midnight
  static const String _tuneParams = '0,0,0,0,0,0,0,0,0';

  /// Get prayer times for a specific date and location
  /// Uses Turkish Diyanet calculation method by default
  Future<PrayerTimesModel?> getPrayerTimes({
    required DateTime date,
    double? latitude,
    double? longitude,
    int? method,
  }) async {
    try {
      final lat = latitude ?? _defaultLatitude;
      final lng = longitude ?? _defaultLongitude;
      final calcMethod = method ?? _calculationMethod;
      
      // Format date as DD-MM-YYYY for better API compatibility
      final formattedDate = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      
      final url = Uri.parse(
        '$_baseUrl/timings/$formattedDate'
        '?latitude=$lat'
        '&longitude=$lng'
        '&method=$calcMethod'
        '&timezonestring=$_timeZone'
        '&tune=$_tuneParams'
        '&adjustment=0'
        '&iso8601=false'
      );

      print('AlAdhan API URL: $url');

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200) {
          return PrayerTimesModel.fromJson(data);
        } else {
          print('AlAdhan API Error: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
      return null;
    }
  }

  /// Get prayer times for today
  Future<PrayerTimesModel?> getTodaysPrayerTimes({
    double? latitude,
    double? longitude,
  }) async {
    return await getPrayerTimes(
      date: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Get Hijri date conversion for a specific Gregorian date
  Future<HijriDate?> getHijriDate({
    required DateTime gregorianDate,
  }) async {
    try {
      final day = gregorianDate.day.toString().padLeft(2, '0');
      final month = gregorianDate.month.toString().padLeft(2, '0');
      final year = gregorianDate.year.toString();
      
      final url = Uri.parse(
        '$_baseUrl/gToH/$day-$month-$year'
      );

      print('AlAdhan Hijri conversion URL: $url');

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['data'] != null) {
          return HijriDate.fromJson(data['data']['hijri']);
        } else {
          print('AlAdhan Hijri API Error: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error converting to Hijri date: $e');
      return null;
    }
  }

  /// Get Gregorian date conversion for a specific Hijri date
  Future<GeorgianDate?> getGregorianDate({
    required int hijriDay,
    required int hijriMonth,
    required int hijriYear,
  }) async {
    try {
      final day = hijriDay.toString().padLeft(2, '0');
      final month = hijriMonth.toString().padLeft(2, '0');
      final year = hijriYear.toString();
      
      final url = Uri.parse(
        '$_baseUrl/hToG/$day-$month-$year'
      );

      print('AlAdhan Gregorian conversion URL: $url');

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['data'] != null) {
          return GeorgianDate.fromJson(data['data']['gregorian']);
        } else {
          print('AlAdhan Gregorian API Error: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error converting to Gregorian date: $e');
      return null;
    }
  }

  /// Get prayer times for a month
  Future<Map<String, PrayerTimesModel>> getMonthlyPrayerTimes({
    required int month,
    required int year,
    double? latitude,
    double? longitude,
    int? method,
  }) async {
    try {
      final lat = latitude ?? _defaultLatitude;
      final lng = longitude ?? _defaultLongitude;
      final calcMethod = method ?? _calculationMethod;
      
      final url = Uri.parse(
        '$_baseUrl/calendar/$year/$month'
        '?latitude=$lat'
        '&longitude=$lng'
        '&method=$calcMethod'
        '&timezonestring=$_timeZone'
        '&tune=$_tuneParams'
        '&adjustment=0'
        '&iso8601=false'
      );

      print('AlAdhan Monthly API URL: $url');

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['data'] != null) {
          final Map<String, PrayerTimesModel> monthlyTimes = {};
          
          for (final dayData in data['data']) {
            final prayerTimes = PrayerTimesModel.fromJson({'data': dayData});
            final day = dayData['date']['gregorian']['day'];
            monthlyTimes[day] = prayerTimes;
          }
          
          return monthlyTimes;
        } else {
          print('AlAdhan Monthly API Error: ${data['status']}');
          return {};
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Error fetching monthly prayer times: $e');
      return {};
    }
  }

  /// Check if the service is available
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status'),
        headers: {'timeout': '5'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('AlAdhan service check failed: $e');
      return false;
    }
  }

  /// Get available calculation methods
  Future<Map<int, String>> getCalculationMethods() async {
    try {
      final url = Uri.parse('$_baseUrl/methods');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['data'] != null) {
          final Map<int, String> methods = {};
          
          data['data'].forEach((key, value) {
            final id = int.tryParse(key);
            if (id != null && value['name'] != null) {
              methods[id] = value['name'];
            }
          });
          
          return methods;
        }
      }
    } catch (e) {
      print('Error fetching calculation methods: $e');
    }
    
    // Return default methods if API fails
    return {
      1: 'University of Islamic Sciences, Karachi',
      2: 'Islamic Society of North America (ISNA)',
      3: 'Muslim World League (MWL)',
      4: 'Umm al-Qura, Makkah',
      5: 'Egyptian General Authority of Survey',
      7: 'Institute of Geophysics, University of Tehran',
      8: 'Gulf Region',
      9: 'Kuwait',
      10: 'Qatar',
      11: 'Majlis Ugama Islam Singapura, Singapore',
      12: 'Union Organization islamic de France',
      13: 'Diyanet İşleri Başkanlığı, Turkey',
      14: 'Spiritual Administration of Muslims of Russia',
    };
  }
}
