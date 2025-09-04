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
  String _currentMonthName = '';
  String _errorMessage = '';
  String _currentLocation = 'Konum alınıyor...';
  
  // Live dashboard variables
  Timer? _timer;
  String _timeUntilNextPrayer = '';
  String _nextPrayerName = '';
  PrayerTimesModel? _todaysPrayerTimes;

  // Turkish month names
  final List<String> _turkishMonths = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

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

      _currentMonthName = '${_turkishMonths[month - 1]} $year';

      final monthlyDataMap = await PrayerApiService.getPrayerTimesForMonth(
        year: year,
        month: month,
      );

      final prayerTimesList = monthlyDataMap.values.toList();

      final today = now.day.toString();
      PrayerTimesModel? todaysPrayer;
      
      if (monthlyDataMap.containsKey(today)) {
        todaysPrayer = monthlyDataMap[today];
      } else if (prayerTimesList.isNotEmpty) {
        todaysPrayer = prayerTimesList.first;
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
              '${_currentLocation}',
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
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Büyük mavi countdown kartı
  Widget _buildCountdownCard() {
    if (_todaysPrayerTimes == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
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

  /// Build today's prayer times card - simple design like APK
  Widget _buildTodayCard() {
    if (_todaysPrayerTimes == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bugün',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  _todaysPrayerTimes!.date,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Next prayer countdown
            if (_nextPrayerName.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sonraki: $_nextPrayerName',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      _timeUntilNextPrayer,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Prayer times grid
            _buildPrayerTimesGrid(_todaysPrayerTimes!),
          ],
        ),
      ),
    );
  }

  /// Build prayer times grid
  Widget _buildPrayerTimesGrid(PrayerTimesModel prayer) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPrayerTimeItem('İmsak', prayer.imsak)),
            Expanded(child: _buildPrayerTimeItem('Güneş', prayer.gunes)),
            Expanded(child: _buildPrayerTimeItem('Öğle', prayer.ogle)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPrayerTimeItem('İkindi', prayer.ikindi)),
            Expanded(child: _buildPrayerTimeItem('Akşam', prayer.aksam)),
            Expanded(child: _buildPrayerTimeItem('Yatsı', prayer.yatsi)),
          ],
        ),
      ],
    );
  }

  /// Build individual prayer time item
  Widget _buildPrayerTimeItem(String name, String time) {
    final isNext = _nextPrayerName.contains(name);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isNext ? Colors.green.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: isNext ? Border.all(color: Colors.green.shade300) : null,
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.ebGaramond(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isNext ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.ebGaramond(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNext ? Colors.green.shade800 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// Build prayer card for monthly list
  Widget _buildPrayerCard(PrayerTimesModel prayer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            prayer.date.split('.')[0],
            style: GoogleFonts.ebGaramond(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
        title: Text(
          prayer.date,
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'İmsak: ${prayer.imsak} • Öğle: ${prayer.ogle} • Akşam: ${prayer.aksam}',
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        onTap: () {
          _showPrayerDetailsDialog(prayer);
        },
      ),
    );
  }

  /// Show prayer details dialog
  void _showPrayerDetailsDialog(PrayerTimesModel prayer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          prayer.date,
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogPrayerTime('İmsak', prayer.imsak),
            _buildDialogPrayerTime('Güneş', prayer.gunes),
            _buildDialogPrayerTime('Öğle', prayer.ogle),
            _buildDialogPrayerTime('İkindi', prayer.ikindi),
            _buildDialogPrayerTime('Akşam', prayer.aksam),
            _buildDialogPrayerTime('Yatsı', prayer.yatsi),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Build dialog prayer time row
  Widget _buildDialogPrayerTime(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            time,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
