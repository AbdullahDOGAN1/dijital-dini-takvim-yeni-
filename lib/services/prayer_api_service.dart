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
  static Future<PrayerTimesModel> getPrayerTimesForToday([String? cityName]) async {
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
    final url = Uri.parse('$_baseUrl/timingsByCity?city=$city&country=Turkey&method=2');
    
    print('Fetching prayer times for $city from: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      
      // Check if the API returned successful data
      if (jsonData['code'] == 200 && jsonData['data'] != null) {
        return PrayerTimesModel.fromJson(jsonData);
      } else {
        throw Exception('API returned error: ${jsonData['status'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  /// Fetch prayer times by coordinates (latitude, longitude)
  static Future<PrayerTimesModel> _getPrayerTimesByCoordinates(double lat, double lng) async {
    final url = Uri.parse('$_baseUrl/timings?latitude=$lat&longitude=$lng&method=2');
    
    print('Fetching prayer times by coordinates: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      
      if (jsonData['code'] == 200 && jsonData['data'] != null) {
        return PrayerTimesModel.fromJson(jsonData);
      } else {
        throw Exception('API returned error: ${jsonData['status'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  /// Provide default prayer times as a fallback when API is unavailable
  static PrayerTimesModel _getDefaultPrayerTimes() {
    print('Using default prayer times (API unavailable)');
    return const PrayerTimesModel(
      imsak: '05:30',
      gunes: '07:00',
      ogle: '12:30',
      ikindi: '15:45',
      aksam: '18:30',
      yatsi: '20:00',
    );
  }

  /// Test the API connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }
}
