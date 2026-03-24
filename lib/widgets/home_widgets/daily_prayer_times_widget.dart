// ignore_for_file: avoid_print

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
    {'name': 'Güneş', 'color': Colors.orange.shade400, 'icon': Icons.wb_sunny},
    {'name': 'Öğle', 'color': Colors.blue.shade400, 'icon': Icons.light_mode},
    {'name': 'İkindi', 'color': Colors.yellow.shade600, 'icon': Icons.sunny},
    {'name': 'Akşam', 'color': Colors.red.shade400, 'icon': Icons.nights_stay},
    {'name': 'Yatsı', 'color': Colors.indigo.shade500, 'icon': Icons.dark_mode},
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.grey.shade900, Colors.grey.shade800]
                    : [Colors.white, Colors.green.shade50],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.green.shade100,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  // Modern Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.green.shade600,
                      gradient: isDark
                          ? null
                          : LinearGradient(
                              colors: [
                                Colors.green.shade600,
                                Colors.teal.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mosque,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bugünün Vakitleri',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currentLocation,
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Prayer Times Content
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  else if (_todaysPrayerTimes != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildPrayerCard(
                                  _prayerData[0],
                                  0,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPrayerCard(
                                  _prayerData[1],
                                  1,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPrayerCard(
                                  _prayerData[2],
                                  2,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPrayerCard(
                                  _prayerData[3],
                                  3,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPrayerCard(
                                  _prayerData[4],
                                  4,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPrayerCard(
                                  _prayerData[5],
                                  5,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Namaz vakitleri yüklenemedi. Lütfen internet bağlantınızı kontrol edin.',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(
    Map<String, dynamic> prayerInfo,
    int index,
    bool isDark,
  ) {
    final prayerName = prayerInfo['name'] as String;
    final prayerColor = prayerInfo['color'] as Color;
    final prayerIcon = prayerInfo['icon'] as IconData;
    final prayerTime = _getPrayerTime(prayerName);
    final isPassed = _isPrayerPassed(prayerName);

    // Determine if it is the NEXT incoming prayer
    // Simplified logic: the first prayer that has NOT passed is highlighted
    bool isNext = false;
    for (var info in _prayerData) {
      if (!_isPrayerPassed(info['name'] as String)) {
        if (info['name'] == prayerName) {
          isNext = true;
        }
        break;
      }
    }

    final cardBgColor = isDark
        ? Colors.grey.shade800
        : (isPassed ? Colors.grey.shade100 : Colors.white);

    final borderColor = isNext
        ? prayerColor.withOpacity(0.5)
        : (isDark ? Colors.white12 : Colors.transparent);

    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 600),
      columnCount: 3,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isNext ? 1.5 : 1),
              boxShadow: [
                if (isNext && !isDark)
                  BoxShadow(
                    color: prayerColor.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                if (!isPassed && !isDark && !isNext)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  prayerIcon,
                  color: isPassed ? Colors.grey.shade400 : prayerColor,
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  prayerName,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    color: isPassed
                        ? Colors.grey.shade500
                        : (isDark ? Colors.white70 : Colors.black54),
                    fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prayerTime,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPassed
                        ? Colors.grey.shade400
                        : (isDark ? Colors.white : Colors.black87),
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
