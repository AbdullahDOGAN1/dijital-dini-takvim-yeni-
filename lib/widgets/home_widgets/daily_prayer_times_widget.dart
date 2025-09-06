import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/prayer_times_model.dart';
import '../../services/prayer_api_service.dart';

class DailyPrayerTimesWidget extends StatefulWidget {
  const DailyPrayerTimesWidget({super.key});

  @override
  State<DailyPrayerTimesWidget> createState() => _DailyPrayerTimesWidgetState();
}

class _DailyPrayerTimesWidgetState extends State<DailyPrayerTimesWidget> {
  PrayerTimesModel? _todaysPrayerTimes;
  bool _isLoading = true;
  String _currentLocation = 'Konum alınıyor...';

  // Prayer data with colors and icons
  final List<Map<String, dynamic>> _prayerData = [
    {
      'name': 'İmsak',
      'color': Colors.purple.shade300,
      'icon': Icons.wb_twilight,
    },
    {
      'name': 'Güneş',
      'color': Colors.orange.shade400,
      'icon': Icons.wb_sunny,
    },
    {
      'name': 'Öğle',
      'color': Colors.blue.shade400,
      'icon': Icons.light_mode,
    },
    {
      'name': 'İkindi',
      'color': Colors.yellow.shade600,
      'icon': Icons.sunny,
    },
    {
      'name': 'Akşam',
      'color': Colors.red.shade400,
      'icon': Icons.nights_stay,
    },
    {
      'name': 'Yatsı',
      'color': Colors.indigo.shade500,
      'icon': Icons.dark_mode,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final now = DateTime.now();
      final monthlyDataMap = await PrayerApiService.getPrayerTimesForMonth(
        year: now.year,
        month: now.month,
      );

      final today = now.day.toString().padLeft(2, '0');
      final todaysPrayer = monthlyDataMap[today];

      setState(() {
        _todaysPrayerTimes = todaysPrayer;
        _isLoading = false;
        _currentLocation = 'Ankara'; // TODO: Get from location service
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading prayer times: $e');
    }
  }

  String _getPrayerTime(String prayerName) {
    if (_todaysPrayerTimes == null) return '--:--';
    
    switch (prayerName) {
      case 'İmsak':
        return _todaysPrayerTimes!.imsak;
      case 'Güneş':
        return _todaysPrayerTimes!.gunes;
      case 'Öğle':
        return _todaysPrayerTimes!.ogle;
      case 'İkindi':
        return _todaysPrayerTimes!.ikindi;
      case 'Akşam':
        return _todaysPrayerTimes!.aksam;
      case 'Yatsı':
        return _todaysPrayerTimes!.yatsi;
      default:
        return '--:--';
    }
  }

  bool _isPrayerPassed(String prayerName) {
    if (_todaysPrayerTimes == null) return false;
    
    final now = DateTime.now();
    final prayerTime = _getPrayerTime(prayerName);
    final timeParts = prayerTime.split(':');
    
    if (timeParts.length >= 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      
      final prayerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      return now.isAfter(prayerDateTime);
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimationConfiguration.staggeredList(
      position: 1,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade700,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mosque,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bugünün Namaz Vakitleri',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _currentLocation,
                              style: GoogleFonts.ebGaramond(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Prayer Times Grid
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else if (_todaysPrayerTimes != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // First row
                        Row(
                          children: [
                            Expanded(
                              child: _buildPrayerCard(_prayerData[0], 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPrayerCard(_prayerData[1], 1),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPrayerCard(_prayerData[2], 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row
                        Row(
                          children: [
                            Expanded(
                              child: _buildPrayerCard(_prayerData[3], 3),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPrayerCard(_prayerData[4], 4),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPrayerCard(_prayerData[5], 5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Namaz vakitleri yüklenemedi',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(Map<String, dynamic> prayerInfo, int index) {
    final prayerName = prayerInfo['name'] as String;
    final prayerColor = prayerInfo['color'] as Color;
    final prayerIcon = prayerInfo['icon'] as IconData;
    final prayerTime = _getPrayerTime(prayerName);
    final isPassed = _isPrayerPassed(prayerName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 600),
      columnCount: 3,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isPassed 
                  ? Colors.grey.withOpacity(0.3)
                  : prayerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPassed 
                    ? Colors.grey.withOpacity(0.5)
                    : prayerColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  prayerIcon,
                  color: isPassed ? Colors.grey : prayerColor,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  prayerName,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPassed 
                        ? Colors.grey 
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prayerTime,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.grey : prayerColor,
                  ),
                ),
                if (isPassed)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Geçti',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
