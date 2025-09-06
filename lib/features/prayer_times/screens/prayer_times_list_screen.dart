import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/prayer_times_model.dart';
import '../../../services/prayer_api_service.dart';

class PrayerTimesListScreen extends StatefulWidget {
  const PrayerTimesListScreen({super.key});

  @override
  State<PrayerTimesListScreen> createState() => _PrayerTimesListScreenState();
}

class _PrayerTimesListScreenState extends State<PrayerTimesListScreen> {
  bool _isLoading = true;
  List<PrayerTimesModel> _monthlyPrayerTimes = [];
  String _errorMessage = '';
  String _currentLocation = 'Konum alınıyor...';
  
  // Live dashboard variables
  Timer? _timer;
  String _timeUntilNextPrayer = '';
  String _nextPrayerName = '';
  PrayerTimesModel? _todaysPrayerTimes;

  @override
  void initState() {
    super.initState();
    _loadLocationInfo();
    _loadMonthlyPrayerTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Load current location information
  Future<void> _loadLocationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool usingCurrentLocation = prefs.getBool('using_current_location') ?? true;
      
      if (!usingCurrentLocation) {
        final String? city = prefs.getString('selected_city');
        final String? country = prefs.getString('selected_country');
        
        if (city != null) {
          setState(() {
            _currentLocation = country != null ? '$city, $country' : city;
          });
        }
      } else {
        final double? lat = prefs.getDouble('current_latitude');
        final double? lng = prefs.getDouble('current_longitude');
        
        if (lat != null && lng != null) {
          final cityName = PrayerApiService.getCityFromCoordinates(lat, lng);
          setState(() {
            _currentLocation = '$cityName (GPS)';
          });
        } else {
          setState(() {
            _currentLocation = 'Konum belirlenemiyor';
          });
        }
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Konum hatası';
      });
    }
  }

  /// Load monthly prayer times
  Future<void> _loadMonthlyPrayerTimes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      final monthlyDataMap = await PrayerApiService.getPrayerTimesForMonth(
        year: year,
        month: month,
      );

      // Debug: API'den gelen veriyi kontrol et
      print('🕌 API Response - Monthly data keys: ${monthlyDataMap.keys.toList()}');
      print('🕌 API Response - Total entries: ${monthlyDataMap.length}');
      if (monthlyDataMap.isNotEmpty) {
        final firstEntry = monthlyDataMap.values.first;
        print('🕌 API Response - First entry: ${firstEntry.date} - Fajr: ${firstEntry.imsak}, Sunrise: ${firstEntry.gunes}');
      }

      final prayerTimesList = monthlyDataMap.values.toList();

      final today = now.day.toString();
      final todayPadded = now.day.toString().padLeft(2, '0');
      PrayerTimesModel? todaysPrayer;
      
      print('🗓️ Bugün: $today (padded: $todayPadded)');
      print('🗓️ Available keys: ${monthlyDataMap.keys.toList()}');
      
      if (monthlyDataMap.containsKey(today)) {
        todaysPrayer = monthlyDataMap[today];
        print('🗓️ Found today with key: $today');
      } else if (monthlyDataMap.containsKey(todayPadded)) {
        todaysPrayer = monthlyDataMap[todayPadded];
        print('🗓️ Found today with padded key: $todayPadded');
      } else if (prayerTimesList.isNotEmpty) {
        todaysPrayer = prayerTimesList.first;
        print('🗓️ Using first entry as fallback');
      }
      
      if (todaysPrayer != null) {
        print('🗓️ Today\'s prayer times: ${todaysPrayer.date}');
        print('🗓️ İmsak: ${todaysPrayer.imsak}, Güneş: ${todaysPrayer.gunes}');
      }

      setState(() {
        _monthlyPrayerTimes = prayerTimesList;
        _todaysPrayerTimes = todaysPrayer;
        _isLoading = false;
      });

      if (todaysPrayer != null) {
        _startTimer();
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Namaz vakitleri yüklenemedi: $e';
      });
    }
  }

  /// Start countdown timer
  void _startTimer() {
    if (_todaysPrayerTimes == null) return;

    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
    
    _updateCountdown();
  }

  /// Update countdown to next prayer
  void _updateCountdown() {
    if (_todaysPrayerTimes == null) return;

    final now = DateTime.now();
    
    final prayerTimes = [
      {'name': 'İmsak', 'time': _todaysPrayerTimes!.imsak},
      {'name': 'Güneş', 'time': _todaysPrayerTimes!.gunes},
      {'name': 'Öğle', 'time': _todaysPrayerTimes!.ogle},
      {'name': 'İkindi', 'time': _todaysPrayerTimes!.ikindi},
      {'name': 'Akşam', 'time': _todaysPrayerTimes!.aksam},
      {'name': 'Yatsı', 'time': _todaysPrayerTimes!.yatsi},
    ];

    DateTime? nextPrayerDateTime;
    String nextPrayerName = '';

    for (final prayer in prayerTimes) {
      final timeParts = prayer['time']!.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        
        final prayerTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        if (prayerTime.isAfter(now)) {
          nextPrayerDateTime = prayerTime;
          nextPrayerName = prayer['name']!;
          break;
        }
      }
    }

    if (nextPrayerDateTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final imsakParts = _todaysPrayerTimes!.imsak.split(':');
      if (imsakParts.length >= 2) {
        final hour = int.tryParse(imsakParts[0]) ?? 0;
        final minute = int.tryParse(imsakParts[1]) ?? 0;
        
        nextPrayerDateTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          hour,
          minute,
        );
        nextPrayerName = 'İmsak (Yarın)';
      }
    }

    if (nextPrayerDateTime == null) {
      setState(() {
        _timeUntilNextPrayer = '00:00:00';
        _nextPrayerName = 'Bilinmiyor';
      });
      return;
    }

    final difference = nextPrayerDateTime.difference(now);
    
    if (difference.isNegative) {
      setState(() {
        _timeUntilNextPrayer = '00:00:00';
        _nextPrayerName = nextPrayerName;
      });
      return;
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    setState(() {
      _timeUntilNextPrayer = 
          '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
      _nextPrayerName = nextPrayerName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eylül 2025',
              style: GoogleFonts.ebGaramond(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              _currentLocation,
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              Navigator.pushNamed(context, '/location_settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadLocationInfo();
              _loadMonthlyPrayerTimes();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ebGaramond(fontSize: 16, color: Colors.red.shade600),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMonthlyPrayerTimes,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Bugünün Namaz Vakitleri header
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Bugünün Namaz Vakitleri',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Büyük mavi countdown kartı
                        _buildCountdownCard(),
                        
                        // Namaz vakitleri kartları
                        _buildPrayerTimesCards(),
                        
                        const SizedBox(height: 24),
                        
                        // Sonraki Günler Başlığı
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Sonraki Günler',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Sonraki günlerin namaz vakitleri
                        _buildNextDaysCards(),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Büyük countdown kartı - sonraki namaza göre renkli
  Widget _buildCountdownCard() {
    if (_todaysPrayerTimes == null) return const SizedBox.shrink();

    // Sonraki namaza göre renk belirle
    Color getPrayerColor() {
      switch (_nextPrayerName.toLowerCase()) {
        case 'imsak':
        case 'İmsak':
          return Colors.purple.shade400;
        case 'güneş':
          return Colors.orange.shade400;
        case 'öğle':
          return Colors.blue.shade400;
        case 'ikindi':
          return Colors.yellow.shade600;
        case 'akşam':
          return Colors.red.shade400;
        case 'yatsı':
          return Colors.indigo.shade500;
        default:
          return Colors.blue.shade400;
      }
    }

    final prayerColor = getPrayerColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            prayerColor.withOpacity(0.6),
            prayerColor,
            prayerColor.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: prayerColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tarih
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Perşembe, 4 Eylül 2025',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sonraki vakit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wb_sunny, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sonraki Vakit: $_nextPrayerName',
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Büyük sayaç
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _timeUntilNextPrayer,
              style: GoogleFonts.ebGaramond(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'kaldı',
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Renkli namaz vakitleri kartları
  Widget _buildPrayerTimesCards() {
    if (_todaysPrayerTimes == null) return const SizedBox.shrink();

    final prayerData = [
      {
        'name': 'İmsak',
        'time': _todaysPrayerTimes!.imsak,
        'color': Colors.purple.shade300,
        'icon': Icons.wb_twilight,
      },
      {
        'name': 'Güneş',
        'time': _todaysPrayerTimes!.gunes,
        'color': Colors.orange.shade400,
        'icon': Icons.wb_sunny,
      },
      {
        'name': 'Öğle',
        'time': _todaysPrayerTimes!.ogle,
        'color': Colors.blue.shade400,
        'icon': Icons.light_mode,
      },
      {
        'name': 'İkindi',
        'time': _todaysPrayerTimes!.ikindi,
        'color': Colors.yellow.shade600,
        'icon': Icons.sunny,
      },
      {
        'name': 'Akşam',
        'time': _todaysPrayerTimes!.aksam,
        'color': Colors.red.shade400,
        'icon': Icons.nights_stay,
      },
      {
        'name': 'Yatsı',
        'time': _todaysPrayerTimes!.yatsi,
        'color': Colors.indigo.shade500,
        'icon': Icons.dark_mode,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: prayerData.map((prayer) {
          final isNext = _nextPrayerName.contains(prayer['name'] as String);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNext ? (prayer['color'] as Color).withOpacity(0.9) : prayer['color'] as Color,
              borderRadius: BorderRadius.circular(16),
              border: isNext ? Border.all(color: Colors.yellow.shade800, width: 3) : null,
              boxShadow: [
                BoxShadow(
                  color: (prayer['color'] as Color).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Sol taraf - Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    prayer['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Namaz adı
                Expanded(
                  child: Text(
                    prayer['name'] as String,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // Sağ taraf - Saat
                Text(
                  prayer['time'] as String,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Sonraki günlerin namaz vakitleri kartları
  Widget _buildNextDaysCards() {
    if (_monthlyPrayerTimes.isEmpty) return const SizedBox.shrink();

    final today = DateTime.now();
    final nextDays = <PrayerTimesModel>[];
    
    print('🔍 Looking for next days starting from: ${today.day}');
    print('🔍 Available prayer data days: ${_monthlyPrayerTimes.map((p) => p.date).toList()}');
    
    // Sonraki 6 günü bul
    for (int i = 1; i <= 6; i++) {
      final targetDate = today.add(Duration(days: i));
      final targetDay = targetDate.day;
      
      print('🔍 Looking for day: $targetDay');
      
      // Aylık verilerden bu günü bul - hem "4" hem "04" formatını kontrol et
      for (final prayer in _monthlyPrayerTimes) {
        final prayerDateParts = prayer.date.split(' ');
        if (prayerDateParts.isNotEmpty) {
          final dayPart = prayerDateParts[0]; // "04" veya "4"
          final prayerDay = int.tryParse(dayPart) ?? 0;
          
          if (prayerDay == targetDay) {
            print('✅ Found prayer data for day $targetDay: ${prayer.date}');
            nextDays.add(prayer);
            break;
          }
        }
      }
      
      // Eğer bulamazsak, ay sonunda bir sonraki aya geçebiliriz
      if (nextDays.length < i) {
        print('❌ Could not find prayer data for day $targetDay');
      }
    }

    print('📋 Total next days found: ${nextDays.length}');

    if (nextDays.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Sonraki günler için namaz vakitleri yüklenemedi.',
          style: GoogleFonts.ebGaramond(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: nextDays.asMap().entries.map((entry) {
        final index = entry.key;
        final prayer = entry.value;
        final targetDate = today.add(Duration(days: index + 1));
        final dayName = _getDayName(targetDate);
        final monthName = _getMonthName(targetDate.month);
        final displayText = '$dayName ${targetDate.day} $monthName';
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  targetDate.day.toString(),
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            title: Text(
              displayText,
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              '${targetDate.day} $monthName ${targetDate.year}',
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNextDayPrayerRow('İmsak', prayer.imsak, Icons.wb_twilight, Colors.purple.shade400),
                    _buildNextDayPrayerRow('Güneş', prayer.gunes, Icons.wb_sunny, Colors.orange.shade400),
                    _buildNextDayPrayerRow('Öğle', prayer.ogle, Icons.light_mode, Colors.blue.shade400),
                    _buildNextDayPrayerRow('İkindi', prayer.ikindi, Icons.sunny, Colors.yellow.shade600),
                    _buildNextDayPrayerRow('Akşam', prayer.aksam, Icons.nights_stay, Colors.red.shade400),
                    _buildNextDayPrayerRow('Yatsı', prayer.yatsi, Icons.dark_mode, Colors.indigo.shade500),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Sonraki günler için namaz vakti satırı
  Widget _buildNextDayPrayerRow(String name, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.ebGaramond(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.ebGaramond(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Gün adını getir
  String _getDayName(DateTime date) {
    const turkishDays = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    return turkishDays[date.weekday - 1];
  }

  /// Ay adını getir
  String _getMonthName(int month) {
    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return turkishMonths[month - 1];
  }
}
