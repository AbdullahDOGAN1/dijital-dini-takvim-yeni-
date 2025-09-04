import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CityLocation {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  CityLocation({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _isLocationEnabled = false;
  String _locationStatus = 'Checking...';
  String _currentLocation = 'Unknown';
  String? _selectedCity;

  // Türkiye'nin tüm şehirleri ve önemli İslami şehirler
  final List<CityLocation> _cities = [
    // Türkiye şehirleri
    CityLocation(name: 'İstanbul', country: 'Türkiye', latitude: 41.0082, longitude: 28.9784),
    CityLocation(name: 'Ankara', country: 'Türkiye', latitude: 39.9334, longitude: 32.8597),
    CityLocation(name: 'İzmir', country: 'Türkiye', latitude: 38.4237, longitude: 27.1428),
    CityLocation(name: 'Bursa', country: 'Türkiye', latitude: 40.1826, longitude: 29.0670),
    CityLocation(name: 'Antalya', country: 'Türkiye', latitude: 36.8969, longitude: 30.7133),
    CityLocation(name: 'Adana', country: 'Türkiye', latitude: 37.0000, longitude: 35.3213),
    CityLocation(name: 'Konya', country: 'Türkiye', latitude: 37.8667, longitude: 32.4833),
    CityLocation(name: 'Gaziantep', country: 'Türkiye', latitude: 37.0662, longitude: 37.3833),
    CityLocation(name: 'Şanlıurfa', country: 'Türkiye', latitude: 37.1591, longitude: 38.7969),
    CityLocation(name: 'Kocaeli', country: 'Türkiye', latitude: 40.8533, longitude: 29.8815),
    CityLocation(name: 'Mersin', country: 'Türkiye', latitude: 36.8000, longitude: 34.6333),
    CityLocation(name: 'Diyarbakır', country: 'Türkiye', latitude: 37.9144, longitude: 40.2306),
    CityLocation(name: 'Kayseri', country: 'Türkiye', latitude: 38.7312, longitude: 35.4787),
    CityLocation(name: 'Eskişehir', country: 'Türkiye', latitude: 39.7767, longitude: 30.5206),
    CityLocation(name: 'Samsun', country: 'Türkiye', latitude: 41.2928, longitude: 36.3313),
    CityLocation(name: 'Trabzon', country: 'Türkiye', latitude: 41.0015, longitude: 39.7178),
    CityLocation(name: 'Denizli', country: 'Türkiye', latitude: 37.7765, longitude: 29.0864),
    CityLocation(name: 'Malatya', country: 'Türkiye', latitude: 38.3552, longitude: 38.3095),
    CityLocation(name: 'Erzurum', country: 'Türkiye', latitude: 39.9334, longitude: 41.2678),
    CityLocation(name: 'Van', country: 'Türkiye', latitude: 38.4982, longitude: 43.4089),
    CityLocation(name: 'Batman', country: 'Türkiye', latitude: 37.8812, longitude: 41.1351),
    CityLocation(name: 'Elazığ', country: 'Türkiye', latitude: 38.6748, longitude: 39.2264),
    CityLocation(name: 'Erzincan', country: 'Türkiye', latitude: 39.7500, longitude: 39.5000),
    CityLocation(name: 'Sivas', country: 'Türkiye', latitude: 39.7477, longitude: 37.0179),
    CityLocation(name: 'Adıyaman', country: 'Türkiye', latitude: 37.7648, longitude: 38.2786),
    CityLocation(name: 'Manisa', country: 'Türkiye', latitude: 38.6191, longitude: 27.4289),
    CityLocation(name: 'Tokat', country: 'Türkiye', latitude: 40.3167, longitude: 36.5500),
    CityLocation(name: 'Kahramanmaraş', country: 'Türkiye', latitude: 37.5858, longitude: 36.9371),
    CityLocation(name: 'Mardin', country: 'Türkiye', latitude: 37.3212, longitude: 40.7245),
    CityLocation(name: 'Afyon', country: 'Türkiye', latitude: 38.7507, longitude: 30.5567),
    CityLocation(name: 'Balıkesir', country: 'Türkiye', latitude: 39.6484, longitude: 27.8826),
    CityLocation(name: 'Tekirdağ', country: 'Türkiye', latitude: 40.9833, longitude: 27.5167),
    CityLocation(name: 'Aydın', country: 'Türkiye', latitude: 37.8560, longitude: 27.8416),
    CityLocation(name: 'Muğla', country: 'Türkiye', latitude: 37.2153, longitude: 28.3636),
    CityLocation(name: 'Ordu', country: 'Türkiye', latitude: 40.9839, longitude: 37.8764),
    CityLocation(name: 'Rize', country: 'Türkiye', latitude: 41.0201, longitude: 40.5234),
    CityLocation(name: 'Giresun', country: 'Türkiye', latitude: 40.9128, longitude: 38.3895),
    CityLocation(name: 'Hatay', country: 'Türkiye', latitude: 36.4018, longitude: 36.3498),
    CityLocation(name: 'Isparta', country: 'Türkiye', latitude: 37.7648, longitude: 30.5566),
    CityLocation(name: 'Bolu', country: 'Türkiye', latitude: 40.5760, longitude: 31.5788),
    CityLocation(name: 'Çorum', country: 'Türkiye', latitude: 40.5506, longitude: 34.9556),
    CityLocation(name: 'Amasya', country: 'Türkiye', latitude: 40.6499, longitude: 35.8353),
    CityLocation(name: 'Kastamonu', country: 'Türkiye', latitude: 41.3887, longitude: 33.7827),
    CityLocation(name: 'Zonguldak', country: 'Türkiye', latitude: 41.4564, longitude: 31.7987),
    CityLocation(name: 'Çanakkale', country: 'Türkiye', latitude: 40.1553, longitude: 26.4142),
    CityLocation(name: 'Kırklareli', country: 'Türkiye', latitude: 41.7333, longitude: 27.2167),
    CityLocation(name: 'Edirne', country: 'Türkiye', latitude: 41.6818, longitude: 26.5623),
    CityLocation(name: 'Uşak', country: 'Türkiye', latitude: 38.6823, longitude: 29.4082),
    CityLocation(name: 'Düzce', country: 'Türkiye', latitude: 40.8438, longitude: 31.1565),
    CityLocation(name: 'Osmaniye', country: 'Türkiye', latitude: 37.0742, longitude: 36.2478),
    CityLocation(name: 'Kırıkkale', country: 'Türkiye', latitude: 39.8468, longitude: 33.5153),
    CityLocation(name: 'Kırşehir', country: 'Türkiye', latitude: 39.1425, longitude: 34.1709),
    CityLocation(name: 'Nevşehir', country: 'Türkiye', latitude: 38.5247, longitude: 34.6857),
    CityLocation(name: 'Niğde', country: 'Türkiye', latitude: 37.9667, longitude: 34.6833),
    CityLocation(name: 'Aksaray', country: 'Türkiye', latitude: 38.3687, longitude: 34.0370),
    CityLocation(name: 'Karaman', country: 'Türkiye', latitude: 37.1759, longitude: 33.2287),
    CityLocation(name: 'Yozgat', country: 'Türkiye', latitude: 39.8181, longitude: 34.8147),
    CityLocation(name: 'Çankırı', country: 'Türkiye', latitude: 40.6013, longitude: 33.6134),
    CityLocation(name: 'Sinop', country: 'Türkiye', latitude: 42.0231, longitude: 35.1531),
    CityLocation(name: 'Bartın', country: 'Türkiye', latitude: 41.5811, longitude: 32.4610),
    CityLocation(name: 'Karabük', country: 'Türkiye', latitude: 41.2061, longitude: 32.6204),
    CityLocation(name: 'Artvin', country: 'Türkiye', latitude: 41.1828, longitude: 41.8183),
    CityLocation(name: 'Gümüşhane', country: 'Türkiye', latitude: 40.4602, longitude: 39.5086),
    CityLocation(name: 'Kars', country: 'Türkiye', latitude: 40.6013, longitude: 43.0975),
    CityLocation(name: 'Ardahan', country: 'Türkiye', latitude: 41.1105, longitude: 42.7022),
    CityLocation(name: 'Iğdır', country: 'Türkiye', latitude: 39.8880, longitude: 44.0048),
    CityLocation(name: 'Ağrı', country: 'Türkiye', latitude: 39.7191, longitude: 43.0503),
    CityLocation(name: 'Bitlis', country: 'Türkiye', latitude: 38.4001, longitude: 42.1084),
    CityLocation(name: 'Muş', country: 'Türkiye', latitude: 38.9462, longitude: 41.7539),
    CityLocation(name: 'Hakkari', country: 'Türkiye', latitude: 37.5744, longitude: 43.7417),
    CityLocation(name: 'Şırnak', country: 'Türkiye', latitude: 37.4187, longitude: 42.4918),
    CityLocation(name: 'Siirt', country: 'Türkiye', latitude: 37.9333, longitude: 41.9500),
    CityLocation(name: 'Bingöl', country: 'Türkiye', latitude: 38.8854, longitude: 40.4989),
    CityLocation(name: 'Tunceli', country: 'Türkiye', latitude: 39.3074, longitude: 39.4388),
    CityLocation(name: 'Bayburt', country: 'Türkiye', latitude: 40.2552, longitude: 40.2249),
    CityLocation(name: 'Kilis', country: 'Türkiye', latitude: 36.7184, longitude: 37.1212),
    CityLocation(name: 'Yalova', country: 'Türkiye', latitude: 40.6500, longitude: 29.2667),
    
    // Önemli İslami şehirler
    CityLocation(name: 'Mecca', country: 'Saudi Arabia', latitude: 21.3891, longitude: 39.8579),
    CityLocation(name: 'Medina', country: 'Saudi Arabia', latitude: 24.5247, longitude: 39.5692),
    CityLocation(name: 'Jerusalem', country: 'Palestine', latitude: 31.7683, longitude: 35.2137),
    CityLocation(name: 'Cairo', country: 'Egypt', latitude: 30.0444, longitude: 31.2357),
    CityLocation(name: 'Damascus', country: 'Syria', latitude: 33.5138, longitude: 36.2765),
    CityLocation(name: 'Baghdad', country: 'Iraq', latitude: 33.3152, longitude: 44.3661),
    CityLocation(name: 'Tehran', country: 'Iran', latitude: 35.6892, longitude: 51.3890),
    CityLocation(name: 'Islamabad', country: 'Pakistan', latitude: 33.6844, longitude: 73.0479),
    CityLocation(name: 'Dhaka', country: 'Bangladesh', latitude: 23.8103, longitude: 90.4125),
    CityLocation(name: 'Kuala Lumpur', country: 'Malaysia', latitude: 3.1390, longitude: 101.6869),
    CityLocation(name: 'Jakarta', country: 'Indonesia', latitude: -6.2088, longitude: 106.8456),
    CityLocation(name: 'Riyadh', country: 'Saudi Arabia', latitude: 24.7136, longitude: 46.6753),
    CityLocation(name: 'Doha', country: 'Qatar', latitude: 25.2854, longitude: 51.5310),
    CityLocation(name: 'Kuwait City', country: 'Kuwait', latitude: 29.3117, longitude: 47.4818),
    CityLocation(name: 'Abu Dhabi', country: 'UAE', latitude: 24.2539, longitude: 54.3773),
    CityLocation(name: 'Dubai', country: 'UAE', latitude: 25.2048, longitude: 55.2708),
    CityLocation(name: 'Muscat', country: 'Oman', latitude: 23.5859, longitude: 58.4059),
    CityLocation(name: 'Manama', country: 'Bahrain', latitude: 26.0667, longitude: 50.5577),
    CityLocation(name: 'Tunis', country: 'Tunisia', latitude: 36.8065, longitude: 10.1815),
    CityLocation(name: 'Rabat', country: 'Morocco', latitude: 34.0209, longitude: -6.8416),
    CityLocation(name: 'Casablanca', country: 'Morocco', latitude: 33.5731, longitude: -7.5898),
    CityLocation(name: 'Algiers', country: 'Algeria', latitude: 36.7538, longitude: 3.0588),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedCity();
    _checkLocationPermission();
  }

  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCity = prefs.getString('selected_city');
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Önce konum servisinin açık olup olmadığını kontrol et
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Konum servisleri kapalı';
          _isLocationEnabled = false;
        });
        
        // Kullanıcıya konum servisini açma fırsatı ver
        final bool? result = await _showLocationServicesDialog();
        if (result == true) {
          // Konum ayarlarına yönlendir
          await Geolocator.openLocationSettings();
        }
        return;
      }

      // 2. Konum iznini kontrol et
      permission = await Geolocator.checkPermission();
      
      // 3. İzin reddedilmişse, istenmelidir
      if (permission == LocationPermission.denied) {
        // İzin iste diyaloğunu göstermeden önce kullanıcıya açıklayıcı diyalog göster
        final bool? shouldRequest = await _showPermissionExplanationDialog();
        if (shouldRequest == true) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() {
              _locationStatus = 'Konum izinleri reddedildi';
              _isLocationEnabled = false;
            });
            return;
          }
        } else {
          setState(() {
            _locationStatus = 'Konum izni isteme işlemi iptal edildi';
            _isLocationEnabled = false;
          });
          return;
        }
      }

      // 4. İzin kalıcı olarak reddedilmişse
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Konum izinleri kalıcı olarak reddedildi';
          _isLocationEnabled = false;
        });
        
        // Kullanıcıya uygulama ayarlarına gitme seçeneği sun
        final bool? openSettings = await _showAppSettingsDialog();
        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }
        return;
      }

      // 5. İzin verilmişse, konum servisini kullan
      setState(() {
        _locationStatus = 'Konum izni verildi';
        _isLocationEnabled = true;
      });

      _getCurrentLocation();
    } catch (e) {
      setState(() {
        _locationStatus = 'Hata: $e';
        _isLocationEnabled = false;
      });
    }
  }
  
  // Konum servisleri kapalı diyaloğu
  Future<bool?> _showLocationServicesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konum Servisleri Kapalı',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Namaz vakitlerini doğru şekilde görüntüleyebilmemiz için konum servislerini açmanız gerekiyor. Konum ayarlarını açmak istiyor musunuz?',
          style: GoogleFonts.ebGaramond(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Hayır',
              style: GoogleFonts.ebGaramond(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              'Ayarları Aç',
              style: GoogleFonts.ebGaramond(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  // İzin açıklaması diyaloğu
  Future<bool?> _showPermissionExplanationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Konum İzni Gerekli',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Nur Vakti, doğru namaz vakitleri ve kıble yönü gösterebilmek için konumunuza ihtiyaç duyar.\n\nKonum bilgileriniz sadece bu amaçla kullanılır ve hiçbir şekilde başkalarıyla paylaşılmaz.\n\nDevam etmek ve konum izni istemek istiyor musunuz?',
          style: GoogleFonts.ebGaramond(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'İptal',
              style: GoogleFonts.ebGaramond(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              'İzin İste',
              style: GoogleFonts.ebGaramond(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  // Uygulama ayarları diyaloğu
  Future<bool?> _showAppSettingsDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konum İzni Reddedildi',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          'Konum izni kalıcı olarak reddedildi. Uygulamanın namaz vakitlerini doğru gösterebilmesi için konum iznini vermeniz gerekiyor.\n\nUygulama ayarlarında izinleri düzenleyebilirsiniz.',
          style: GoogleFonts.ebGaramond(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Kapat',
              style: GoogleFonts.ebGaramond(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text(
              'Ayarları Aç',
              style: GoogleFonts.ebGaramond(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get closest Turkish city
      final closestCity = _getClosestTurkishCity(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = 'GPS: $closestCity\nLat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
      });
      
      // Save current location to preferences for prayer times
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('current_latitude', position.latitude);
      await prefs.setDouble('current_longitude', position.longitude);
      await prefs.setBool('using_current_location', true);
      
    } catch (e) {
      setState(() {
        _currentLocation = 'Error getting location: $e';
      });
    }
  }

  /// Get closest Turkish city from GPS coordinates
  String _getClosestTurkishCity(double latitude, double longitude) {
    double minDistance = double.infinity;
    String closestCity = 'Bilinmeyen Konum';
    
    // Check if coordinates are within Turkey bounds
    if (latitude < 35.0 || latitude > 43.0 || longitude < 25.0 || longitude > 45.0) {
      return 'Türkiye Dışında';
    }

    for (final city in _cities) {
      if (city.country != 'Türkiye') continue;
      
      final distance = Geolocator.distanceBetween(
        latitude, longitude, city.latitude, city.longitude
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = city.name;
      }
    }

    final distanceKm = minDistance / 1000;
    return '$closestCity (~${distanceKm.toStringAsFixed(1)} km)';
  }

  Future<void> _onCitySelected(CityLocation city) async {
    setState(() {
      _selectedCity = city.name;
      _currentLocation = '${city.name}, ${city.country} (Lat: ${city.latitude}, Lng: ${city.longitude})';
    });
    
    // Save selected city to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_city', city.name);
    await prefs.setDouble('selected_latitude', city.latitude);
    await prefs.setDouble('selected_longitude', city.longitude);
    await prefs.setString('selected_country', city.country);
    await prefs.setBool('using_current_location', false);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Konum ${city.name} olarak güncellendi'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCitySelectionDialog() {
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredCities = _cities.where((city) {
              return city.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                     city.country.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();
            
            // Sort cities: Turkish cities first, then others
            filteredCities.sort((a, b) {
              if (a.country == 'Türkiye' && b.country != 'Türkiye') return -1;
              if (a.country != 'Türkiye' && b.country == 'Türkiye') return 1;
              return a.name.compareTo(b.name);
            });

            return AlertDialog(
              title: Text(
                'Şehir Seçin',
                style: GoogleFonts.ebGaramond(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              content: Container(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Şehir ara...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // City list
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredCities.length,
                        separatorBuilder: (context, index) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final city = filteredCities[index];
                          final isSelected = _selectedCity == city.name;
                          
                          return ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: city.country == 'Türkiye' 
                                    ? Colors.red.shade100 
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                city.country == 'Türkiye' 
                                    ? Icons.location_city 
                                    : Icons.public,
                                color: city.country == 'Türkiye' 
                                    ? Colors.red.shade600 
                                    : Colors.blue.shade600,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              city.name,
                              style: GoogleFonts.ebGaramond(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.green.shade700 : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              city.country,
                              style: GoogleFonts.ebGaramond(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: isSelected 
                                ? Icon(Icons.check_circle, color: Colors.green.shade600)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              _onCitySelected(city);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'İptal',
                    style: GoogleFonts.ebGaramond(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Konum Ayarları',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isLocationEnabled ? Icons.location_on : Icons.location_off,
                            color: _isLocationEnabled ? Colors.green : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Konum Durumu',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _locationStatus,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: _isLocationEnabled ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isLocationEnabled) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mevcut Konum',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentLocation,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Konumu Yenile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Quick City Selection Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_city,
                            color: Colors.purple,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Şehir Seçimi',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedCity != null 
                            ? 'Seçili şehir: $_selectedCity' 
                            : 'Henüz şehir seçilmemiş',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: _selectedCity != null ? Colors.purple : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showCitySelectionDialog,
                              icon: const Icon(Icons.location_city),
                              label: const Text('Şehir Seç'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          if (_selectedCity != null) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('selected_city');
                                await prefs.remove('selected_latitude');
                                await prefs.remove('selected_longitude');
                                await prefs.remove('selected_country');
                                await prefs.setBool('using_current_location', true);
                                
                                setState(() {
                                  _selectedCity = null;
                                });
                                
                                // If location is enabled, refresh current location
                                if (_isLocationEnabled) {
                                  _getCurrentLocation();
                                } else {
                                  setState(() {
                                    _currentLocation = 'Unknown';
                                  });
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Şehir seçimi temizlendi'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Temizle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Konum Kullanımı',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Konum izni, aşağıdaki özellikler için kullanılır:\n\n'
                        '• Namaz vakitlerinin hesaplanması\n'
                        '• Kıble yönünün belirlenmesi\n'
                        '• Bölgesel dini etkinlikler\n\n'
                        'Konum bilgileriniz cihazınızda saklanır ve paylaşılmaz.',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (!_isLocationEnabled)
                Card(
                  elevation: 4,
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_outlined,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Konum İzni Gerekli',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Namaz vakitleri ve kıble yönü için konum izni gereklidir. İzin vermeden uygulama doğru çalışamaz.',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 16,
                            height: 1.4,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Not: İzin istendikten sonra "İzin Ver" seçeneğine tıklamanız gerekecektir.',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _checkLocationPermission,
                            icon: const Icon(Icons.location_searching, size: 24),
                            label: Text(
                              'Konum İzni Ver',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.red.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              await Geolocator.openAppSettings();
                            },
                            icon: Icon(Icons.settings, size: 18, color: Colors.blue.shade700),
                            label: Text(
                              'Uygulama Ayarlarını Aç',
                              style: GoogleFonts.ebGaramond(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

