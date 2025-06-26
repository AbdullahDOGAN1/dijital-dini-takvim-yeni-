import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';

/// Service class for fetching prayer times from external API
class PrayerApiService {
  // Base URL for Aladhan API - a reliable Islamic prayer times API
  static const String _baseUrl = 'http://api.aladhan.com/v1';

  // Ankara coordinates for backup geocoding approach
  static const double _ankaraLat = 39.9334;
  static const double _ankaraLng = 32.8597;

  /// Fetch prayer times for today for a specific city
  /// Uses Ankara, Turkey as the default location
  static Future<PrayerTimesModel> getPrayerTimesForToday([
    String? cityName,
  ]) async {
    try {
      // Try the city-based approach first
      if (cityName != null && cityName.isNotEmpty) {
        return await _getPrayerTimesByCity(cityName);
      }

      // Fallback to Ankara by city name
      return await _getPrayerTimesByCity('Ankara');
    } catch (e) {
      // If city approach fails, try coordinates
      print('City-based request failed: $e');
      try {
        return await _getPrayerTimesByCoordinates(_ankaraLat, _ankaraLng);
      } catch (e2) {
        print('Coordinate-based request failed: $e2');
        // Return default prayer times as last resort
        return _getDefaultPrayerTimes();
      }
    }
  }

  /// Fetch prayer times by city name and country
  static Future<PrayerTimesModel> _getPrayerTimesByCity(String city) async {
    final url = Uri.parse(
      '$_baseUrl/timingsByCity?city=$city&country=Turkey&method=2',
    );

    print('Fetching prayer times for $city from: $url');

    final response = await http
        .get(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);

      // Check if the API returned successful data
      if (jsonData['code'] == 200 && jsonData['data'] != null) {
        return PrayerTimesModel.fromJson(jsonData);
      } else {
        throw Exception(
          'API returned error: ${jsonData['status'] ?? 'Unknown error'}',
        );
      }
    } else {
      throw Exception(
        'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  /// Fetch prayer times by coordinates (latitude, longitude)
  static Future<PrayerTimesModel> _getPrayerTimesByCoordinates(
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/timings?latitude=$lat&longitude=$lng&method=2',
    );

    print('Fetching prayer times by coordinates: $url');

    final response = await http
        .get(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData['code'] == 200 && jsonData['data'] != null) {
        return PrayerTimesModel.fromJson(jsonData);
      } else {
        throw Exception(
          'API returned error: ${jsonData['status'] ?? 'Unknown error'}',
        );
      }
    } else {
      throw Exception(
        'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  /// Provide default prayer times as a fallback when API is unavailable
  static PrayerTimesModel _getDefaultPrayerTimes() {
    print('Using default prayer times (API unavailable)');
    final now = DateTime.now();
    return PrayerTimesModel(
      imsak: '05:30',
      gunes: '07:00',
      ogle: '12:30',
      ikindi: '15:45',
      aksam: '18:30',
      yatsi: '20:00',
      date: '${now.day} ${_getMonthName(now.month)} ${now.year}',
    );
  }

  /// Fetch prayer times for entire month using coordinates
  /// Returns a list of daily prayer times for the specified month
  static Future<List<Map<String, dynamic>>> getPrayerTimesForMonth({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Use Aladhan API's calendar endpoint for monthly data with coordinates
      final url = Uri.parse(
        '$_baseUrl/calendar?latitude=$latitude&longitude=$longitude&method=2&month=$month&year=$year',
      );

      print('Fetching monthly prayer times for coordinates ($latitude, $longitude) ($month/$year) from: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('Monthly prayer times response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Check if the API returned successful data
        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          // The API returns an array of daily prayer times
          final List<dynamic> dailyData = jsonData['data'];
          
          // Convert to List<Map<String, dynamic>>
          return dailyData.map((day) => day as Map<String, dynamic>).toList();
        } else {
          throw Exception(
            'API returned error: ${jsonData['status'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Monthly prayer times request failed: $e');
      // Return fallback data for the month
      return _getDefaultMonthlyPrayerTimes(year, month);
    }
  }

  /// Provide default monthly prayer times as fallback
  static List<Map<String, dynamic>> _getDefaultMonthlyPrayerTimes(
    int year,
    int month,
  ) {
    print('Using default monthly prayer times (API unavailable)');
    
    // Get the number of days in the month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<Map<String, dynamic>> defaultMonth = [];

    for (int day = 1; day <= daysInMonth; day++) {
      defaultMonth.add({
        'timings': {
          'Imsak': '05:30',
          'Fajr': '05:45',
          'Sunrise': '07:15',
          'Dhuhr': '12:30',
          'Asr': '15:45',
          'Maghrib': '18:30',
          'Isha': '20:00',
        },
        'date': {
          'gregorian': {
            'day': day.toString().padLeft(2, '0'),
            'month': {
              'number': month,
              'en': _getMonthName(month),
            },
            'year': year.toString(),
            'weekday': {
              'en': _getWeekdayName(DateTime(year, month, day).weekday),
            },
          },
        },
      });
    }

    return defaultMonth;
  }

  /// Helper method to get month name
  static String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  /// Helper method to get weekday name
  static String _getWeekdayName(int weekday) {
    const weekdays = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[weekday];
  }

  /// Test the API connection
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/status'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }
}
