import '../models/prayer_times_model.dart';
import 'aladhan_api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for fetching prayer times from external API
/// Now uses AlAdhan API with Turkish Diyanet calculation method and location services
class PrayerApiService {
  static final AlAdhanApiService _alAdhanService = AlAdhanApiService();
  
  // Türkiye'nin büyük şehirleri ve koordinatları
  static const Map<String, Map<String, double>> turkishCities = {
    'Adana': {'lat': 37.0000, 'lng': 35.3213},
    'Adıyaman': {'lat': 37.7648, 'lng': 38.2786},
    'Afyonkarahisar': {'lat': 38.7507, 'lng': 30.5567},
    'Ağrı': {'lat': 39.7191, 'lng': 43.0503},
    'Aksaray': {'lat': 38.3687, 'lng': 34.0370},
    'Amasya': {'lat': 40.6499, 'lng': 35.8353},
    'Ankara': {'lat': 39.9334, 'lng': 32.8597},
    'Antalya': {'lat': 36.8969, 'lng': 30.7133},
    'Ardahan': {'lat': 41.1105, 'lng': 42.7022},
    'Artvin': {'lat': 41.1828, 'lng': 41.8183},
    'Aydın': {'lat': 37.8560, 'lng': 27.8416},
    'Balıkesir': {'lat': 39.6484, 'lng': 27.8826},
    'Bartın': {'lat': 41.5811, 'lng': 32.4610},
    'Batman': {'lat': 37.8812, 'lng': 41.1351},
    'Bayburt': {'lat': 40.2552, 'lng': 40.2249},
    'Bilecik': {'lat': 40.1553, 'lng': 29.9833},
    'Bingöl': {'lat': 38.8815, 'lng': 40.4982},
    'Bitlis': {'lat': 38.3938, 'lng': 42.1232},
    'Bolu': {'lat': 40.5760, 'lng': 31.5788},
    'Burdur': {'lat': 37.7267, 'lng': 30.2917},
    'Bursa': {'lat': 40.1885, 'lng': 29.0610},
    'Çanakkale': {'lat': 40.1553, 'lng': 26.4142},
    'Çankırı': {'lat': 40.6013, 'lng': 33.6134},
    'Çorum': {'lat': 40.5506, 'lng': 34.9556},
    'Denizli': {'lat': 37.7765, 'lng': 29.0864},
    'Diyarbakır': {'lat': 37.9144, 'lng': 40.2306},
    'Düzce': {'lat': 40.8438, 'lng': 31.1565},
    'Edirne': {'lat': 41.6818, 'lng': 26.5623},
    'Elazığ': {'lat': 38.6748, 'lng': 39.2226},
    'Erzincan': {'lat': 39.7500, 'lng': 39.5000},
    'Erzurum': {'lat': 39.9043, 'lng': 41.2678},
    'Eskişehir': {'lat': 39.7667, 'lng': 30.5256},
    'Gaziantep': {'lat': 37.0662, 'lng': 37.3833},
    'Giresun': {'lat': 40.9128, 'lng': 38.3895},
    'Gümüşhane': {'lat': 40.4386, 'lng': 39.5086},
    'Hakkari': {'lat': 37.5744, 'lng': 43.7425},
    'Hatay': {'lat': 36.4018, 'lng': 36.3498},
    'Iğdır': {'lat': 39.8880, 'lng': 44.0048},
    'Isparta': {'lat': 37.7648, 'lng': 30.5566},
    'İstanbul': {'lat': 41.0082, 'lng': 28.9784},
    'İzmir': {'lat': 38.4192, 'lng': 27.1287},
    'Kahramanmaraş': {'lat': 37.5858, 'lng': 36.9371},
    'Karabük': {'lat': 41.2061, 'lng': 32.6204},
    'Karaman': {'lat': 37.1759, 'lng': 33.2287},
    'Kars': {'lat': 40.6013, 'lng': 43.0975},
    'Kastamonu': {'lat': 41.3887, 'lng': 33.7827},
    'Kayseri': {'lat': 38.7312, 'lng': 35.4787},
    'Kırıkkale': {'lat': 39.8468, 'lng': 33.5153},
    'Kırklareli': {'lat': 41.7333, 'lng': 27.2167},
    'Kırşehir': {'lat': 39.1425, 'lng': 34.1709},
    'Kilis': {'lat': 36.7184, 'lng': 37.1212},
    'Kocaeli': {'lat': 40.8533, 'lng': 29.8815},
    'Konya': {'lat': 37.8667, 'lng': 32.4833},
    'Kütahya': {'lat': 39.4167, 'lng': 29.9833},
    'Malatya': {'lat': 38.3552, 'lng': 38.3095},
    'Manisa': {'lat': 38.6191, 'lng': 27.4289},
    'Mardin': {'lat': 37.3212, 'lng': 40.7245},
    'Mersin': {'lat': 36.8000, 'lng': 34.6333},
    'Muğla': {'lat': 37.2153, 'lng': 28.3636},
    'Muş': {'lat': 38.9462, 'lng': 41.7539},
    'Nevşehir': {'lat': 38.6939, 'lng': 34.6857},
    'Niğde': {'lat': 37.9667, 'lng': 34.6833},
    'Ordu': {'lat': 40.9839, 'lng': 37.8764},
    'Osmaniye': {'lat': 37.0742, 'lng': 36.2464},
    'Rize': {'lat': 41.0201, 'lng': 40.5234},
    'Sakarya': {'lat': 40.6940, 'lng': 30.4358},
    'Samsun': {'lat': 41.2928, 'lng': 36.3313},
    'Siirt': {'lat': 37.9333, 'lng': 41.9500},
    'Sinop': {'lat': 42.0231, 'lng': 35.1531},
    'Sivas': {'lat': 39.7477, 'lng': 37.0179},
    'Şanlıurfa': {'lat': 37.1591, 'lng': 38.7969},
    'Şırnak': {'lat': 37.4187, 'lng': 42.4918},
    'Tekirdağ': {'lat': 40.9833, 'lng': 27.5167},
    'Tokat': {'lat': 40.3167, 'lng': 36.5500},
    'Trabzon': {'lat': 41.0015, 'lng': 39.7178},
    'Tunceli': {'lat': 39.3074, 'lng': 39.4388},
    'Uşak': {'lat': 38.6823, 'lng': 29.4082},
    'Van': {'lat': 38.4891, 'lng': 43.4089},
    'Yalova': {'lat': 40.6500, 'lng': 29.2667},
    'Yozgat': {'lat': 39.8181, 'lng': 34.8147},
    'Zonguldak': {'lat': 41.4564, 'lng': 31.7987},
  };

  /// Get current location using Geolocator
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get city name from coordinates using reverse geocoding
  static String getCityFromCoordinates(double latitude, double longitude) {
    double minDistance = double.infinity;
    String closestCity = 'Ankara'; // Default
    
    // Türkiye sınırları kontrolü
    if (latitude < 35.0 || latitude > 43.0 || longitude < 25.0 || longitude > 45.0) {
      print('Coordinates outside Turkey bounds, using Ankara');
      return 'Ankara';
    }

    for (final entry in turkishCities.entries) {
      final cityLat = entry.value['lat']!;
      final cityLng = entry.value['lng']!;
      
      final distance = Geolocator.distanceBetween(
        latitude, longitude, cityLat, cityLng
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = entry.key;
      }
    }

    // Eğer en yakın şehir çok uzaksa (100km+), Ankara kullan
    if (minDistance > 100000) {
      print('Closest city too far (${minDistance/1000}km), using Ankara');
      return 'Ankara';
    }

    print('Closest city to ($latitude, $longitude): $closestCity (${minDistance/1000}km away)');
    return closestCity;
  }

  /// Get saved location from SharedPreferences
  static Future<Map<String, double>?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool usingCurrentLocation = prefs.getBool('using_current_location') ?? true;
      
      if (!usingCurrentLocation) {
        // User has selected a specific city
        final double? lat = prefs.getDouble('selected_latitude');
        final double? lng = prefs.getDouble('selected_longitude');
        final String? city = prefs.getString('selected_city');
        
        if (lat != null && lng != null) {
          print('Using saved city location: $city ($lat, $lng)');
          return {'latitude': lat, 'longitude': lng};
        }
      } else {
        // Try to use current location
        final double? lat = prefs.getDouble('current_latitude');
        final double? lng = prefs.getDouble('current_longitude');
        
        if (lat != null && lng != null) {
          print('Using saved current location: ($lat, $lng)');
          return {'latitude': lat, 'longitude': lng};
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting saved location: $e');
      return null;
    }
  }

  /// Fetch prayer times for today with automatic location detection
  static Future<PrayerTimesModel> getPrayerTimesForToday([
    double? latitude,
    double? longitude,
  ]) async {
    try {
      double? lat = latitude;
      double? lng = longitude;

      // If coordinates not provided, try to get from saved preferences first
      if (lat == null || lng == null) {
        final savedLocation = await getSavedLocation();
        if (savedLocation != null) {
          lat = savedLocation['latitude'];
          lng = savedLocation['longitude'];
        } else {
          // Try to get current location
          final position = await getCurrentLocation();
          if (position != null) {
            lat = position.latitude;
            lng = position.longitude;
            
            // Save current location to preferences for future use
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('current_latitude', lat);
            await prefs.setDouble('current_longitude', lng);
          } else {
            // Fallback to Ankara coordinates
            lat = 39.9334;
            lng = 32.8597;
            print('Using default Ankara coordinates');
          }
        }
      }

      // Use AlAdhan API service for accurate prayer times
      final prayerTimes = await _alAdhanService.getTodaysPrayerTimes(
        latitude: lat,
        longitude: lng,
      );

      if (prayerTimes != null) {
        // Add city information to the prayer times
        final cityName = getCityFromCoordinates(lat!, lng!);
        print('Prayer times for: $cityName ($lat, $lng)');
        return prayerTimes;
      } else {
        // Return default prayer times if API fails
        return _getDefaultPrayerTimes();
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
      return _getDefaultPrayerTimes();
    }
  }

  /// Fetch prayer times for today by city name
  static Future<PrayerTimesModel> getPrayerTimesForCity(String cityName) async {
    try {
      if (turkishCities.containsKey(cityName)) {
        final coordinates = turkishCities[cityName]!;
        final lat = coordinates['lat']!;
        final lng = coordinates['lng']!;

        final prayerTimes = await _alAdhanService.getTodaysPrayerTimes(
          latitude: lat,
          longitude: lng,
        );

        if (prayerTimes != null) {
          print('Prayer times for: $cityName');
          return prayerTimes;
        }
      } else {
        print('City not found: $cityName');
      }
      
      return _getDefaultPrayerTimes();
    } catch (e) {
      print('Error fetching prayer times for city: $e');
      return _getDefaultPrayerTimes();
    }
  }

  /// Fetch prayer times for a specific date and location
  static Future<PrayerTimesModel> getPrayerTimesForDate({
    required DateTime date,
    double? latitude,
    double? longitude,
  }) async {
    try {
      double? lat = latitude;
      double? lng = longitude;

      // If coordinates not provided, try to get from saved preferences
      if (lat == null || lng == null) {
        final savedLocation = await getSavedLocation();
        if (savedLocation != null) {
          lat = savedLocation['latitude'];
          lng = savedLocation['longitude'];
        } else {
          // Fallback to Ankara coordinates
          lat = 39.9334;
          lng = 32.8597;
          print('Using default Ankara coordinates for date: ${date.toString()}');
        }
      }

      final prayerTimes = await _alAdhanService.getPrayerTimes(
        date: date,
        latitude: lat,
        longitude: lng,
      );

      if (prayerTimes != null) {
        return prayerTimes;
      } else {
        return _getDefaultPrayerTimes();
      }
    } catch (e) {
      print('Error fetching prayer times for date: $e');
      return _getDefaultPrayerTimes();
    }
  }

  /// Fetch prayer times for entire month using coordinates with automatic location
  static Future<Map<String, PrayerTimesModel>> getPrayerTimesForMonth({
    required int year,
    required int month,
    double? latitude,
    double? longitude,
  }) async {
    try {
      double? lat = latitude;
      double? lng = longitude;

      // If coordinates not provided, try to get from saved preferences
      if (lat == null || lng == null) {
        final savedLocation = await getSavedLocation();
        if (savedLocation != null) {
          lat = savedLocation['latitude'];
          lng = savedLocation['longitude'];
        } else {
          // Try to get current location
          final position = await getCurrentLocation();
          if (position != null) {
            lat = position.latitude;
            lng = position.longitude;
          } else {
            // Fallback to Ankara coordinates
            lat = 39.9334;
            lng = 32.8597;
            print('Using default Ankara coordinates for monthly data');
          }
        }
      }

      final cityName = getCityFromCoordinates(lat!, lng!);
      print('Monthly prayer times for: $cityName ($lat, $lng)');

      return await _alAdhanService.getMonthlyPrayerTimes(
        month: month,
        year: year,
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      print('Error fetching monthly prayer times: $e');
      return _getDefaultMonthlyPrayerTimes(year, month);
    }
  }

  /// Fetch prayer times for entire month by city name
  static Future<Map<String, PrayerTimesModel>> getPrayerTimesForMonthByCity({
    required int year,
    required int month,
    required String cityName,
  }) async {
    try {
      if (turkishCities.containsKey(cityName)) {
        final coordinates = turkishCities[cityName]!;
        final lat = coordinates['lat']!;
        final lng = coordinates['lng']!;

        print('Monthly prayer times for: $cityName');

        return await _alAdhanService.getMonthlyPrayerTimes(
          month: month,
          year: year,
          latitude: lat,
          longitude: lng,
        );
      } else {
        print('City not found: $cityName');
        return _getDefaultMonthlyPrayerTimes(year, month);
      }
    } catch (e) {
      print('Error fetching monthly prayer times for city: $e');
      return _getDefaultMonthlyPrayerTimes(year, month);
    }
  }

  /// Get Hijri date for a specific Gregorian date
  static Future<HijriDate?> getHijriDate(DateTime gregorianDate) async {
    try {
      return await _alAdhanService.getHijriDate(gregorianDate: gregorianDate);
    } catch (e) {
      print('Error fetching Hijri date: $e');
      return null;
    }
  }

  /// Test the API connection
  static Future<bool> testConnection() async {
    try {
      return await _alAdhanService.isServiceAvailable();
    } catch (e) {
      print('API connection test failed: $e');
      return false;
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

  /// Provide default monthly prayer times as fallback
  static Map<String, PrayerTimesModel> _getDefaultMonthlyPrayerTimes(
    int year,
    int month,
  ) {
    print('Using default monthly prayer times (API unavailable)');
    
    // Get the number of days in the month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final Map<String, PrayerTimesModel> defaultMonth = {};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      defaultMonth[day.toString()] = PrayerTimesModel(
        imsak: '05:30',
        gunes: '07:00',
        ogle: '12:30',
        ikindi: '15:45',
        aksam: '18:30',
        yatsi: '20:00',
        date: '${date.day} ${_getMonthName(date.month)} ${date.year}',
      );
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
}
