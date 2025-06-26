import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/prayer_times_model.dart';
import '../../../services/prayer_api_service.dart';

class PrayerTimesListScreen extends StatefulWidget {
  const PrayerTimesListScreen({super.key});

  @override
  State<PrayerTimesListScreen> createState() => _PrayerTimesListScreenState();
}

class _PrayerTimesListScreenState extends State<PrayerTimesListScreen> {
  // State variables
  bool _isLoading = true;
  List<PrayerTimesModel> _monthlyPrayerTimes = [];
  String _currentMonthName = '';
  String _errorMessage = '';
  
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
    _loadMonthlyPrayerTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Load monthly prayer times with location
  Future<void> _loadMonthlyPrayerTimes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get current location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      double latitude = 39.9334; // Default to Ankara
      double longitude = 32.8597;

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (e) {
          print('Location error, using default: $e');
        }
      }

      // Get current date
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      // Set month name
      _currentMonthName = '${_turkishMonths[month - 1]} $year';

      // Fetch monthly prayer times
      final monthlyData = await PrayerApiService.getPrayerTimesForMonth(
        latitude: latitude,
        longitude: longitude,
        year: year,
        month: month,
      );

      // Convert to PrayerTimesModel objects
      final prayerTimesList = monthlyData.map((dayData) {
        return PrayerTimesModel.fromJson(dayData);
      }).toList();

      // Find today's prayer times
      final today = now.day;
      PrayerTimesModel? todaysPrayer;
      
      try {
        todaysPrayer = prayerTimesList.firstWhere(
          (prayer) => int.parse(prayer.date.split(' ')[0]) == today,
        );
      } catch (e) {
        print('Could not find today\'s prayer times: $e');
        if (prayerTimesList.isNotEmpty) {
          todaysPrayer = prayerTimesList.first;
        }
      }

      setState(() {
        _monthlyPrayerTimes = prayerTimesList;
        _todaysPrayerTimes = todaysPrayer;
        _isLoading = false;
      });

      // Start countdown timer
      if (todaysPrayer != null) {
        _startTimer();
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Aylık namaz vakitleri yüklenemedi: $e';
      });
      print('Error loading monthly prayer times: $e');
    }
  }

  /// Start countdown timer for next prayer
  void _startTimer() {
    if (_todaysPrayerTimes == null) return;

    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
    
    // Initial update
    _updateCountdown();
  }

  /// Update countdown to next prayer
  void _updateCountdown() {
    if (_todaysPrayerTimes == null) return;

    final now = DateTime.now();
    
    // Create list of today's prayer times with DateTime objects
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

    // Find next prayer today
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

    // If no prayer left today, use tomorrow's first prayer (Imsak)
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

    // Calculate remaining time
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

  /// Build today's dashboard widget
  Widget _buildTodayDashboard() {
    if (_todaysPrayerTimes == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Bugünün Namaz Vakitleri',
            style: GoogleFonts.ebGaramond(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Live countdown card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade300.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Sonraki Vakit: $_nextPrayerName',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _timeUntilNextPrayer,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'kaldı',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Today's prayer times grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPrayerTimeRow('İmsak', _todaysPrayerTimes!.imsak, Icons.wb_twilight),
                _buildPrayerTimeRow('Güneş', _todaysPrayerTimes!.gunes, Icons.wb_sunny),
                _buildPrayerTimeRow('Öğle', _todaysPrayerTimes!.ogle, Icons.light_mode),
                _buildPrayerTimeRow('İkindi', _todaysPrayerTimes!.ikindi, Icons.sunny),
                _buildPrayerTimeRow('Akşam', _todaysPrayerTimes!.aksam, Icons.nights_stay),
                _buildPrayerTimeRow('Yatsı', _todaysPrayerTimes!.yatsi, Icons.dark_mode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build prayer time row with icon
  Widget _buildPrayerTimeRow(String name, String time, IconData icon) {
    final isNext = _nextPrayerName.contains(name);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isNext ? Colors.green.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isNext ? Border.all(color: Colors.green.shade300, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNext ? Colors.green.shade600 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isNext ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                color: isNext ? Colors.green.shade800 : Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
              color: isNext ? Colors.green.shade800 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// Build upcoming days list header
  Widget _buildUpcomingDaysHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Sonraki Günler',
        style: GoogleFonts.ebGaramond(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  /// Build upcoming days list item
  Widget _buildUpcomingDayItem(PrayerTimesModel prayer, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prayer.date,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallPrayerTime('İmsak', prayer.imsak),
              _buildSmallPrayerTime('Güneş', prayer.gunes),
              _buildSmallPrayerTime('Öğle', prayer.ogle),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallPrayerTime('İkindi', prayer.ikindi),
              _buildSmallPrayerTime('Akşam', prayer.aksam),
              _buildSmallPrayerTime('Yatsı', prayer.yatsi),
            ],
          ),
        ],
      ),
    );
  }

  /// Build small prayer time widget
  Widget _buildSmallPrayerTime(String name, String time) {
    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.ebGaramond(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: GoogleFonts.ebGaramond(
            fontSize: 14,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentMonthName,
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMonthlyPrayerTimes,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.teal.shade50],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 16,
                            color: Colors.red.shade600,
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
                        // Today's dashboard
                        _buildTodayDashboard(),
                        
                        // Upcoming days header
                        _buildUpcomingDaysHeader(),
                        
                        // Upcoming days list
                        if (_monthlyPrayerTimes.length > 1)
                          ...List.generate(
                            _monthlyPrayerTimes.length - 1,
                            (index) {
                              // Skip today (first item)
                              final prayer = _monthlyPrayerTimes[index + 1];
                              return _buildUpcomingDayItem(prayer, index);
                            },
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Sonraki günler bulunamadı',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
