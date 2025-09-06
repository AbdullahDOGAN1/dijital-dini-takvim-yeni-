import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/prayer_times_model.dart';
import '../../services/prayer_api_service.dart';

class NextPrayerCountdownWidget extends StatefulWidget {
  const NextPrayerCountdownWidget({super.key});

  @override
  State<NextPrayerCountdownWidget> createState() => _NextPrayerCountdownWidgetState();
}

class _NextPrayerCountdownWidgetState extends State<NextPrayerCountdownWidget> {
  Timer? _timer;
  String _timeUntilNextPrayer = '';
  String _nextPrayerName = '';
  String _nextPrayerTime = '';
  double _progressPercent = 0.0;
  PrayerTimesModel? _todaysPrayerTimes;
  bool _isLoading = true;

  // Prayer colors
  final Map<String, Color> _prayerColors = {
    'İmsak': Colors.purple.shade400,
    'Güneş': Colors.orange.shade400,
    'Öğle': Colors.blue.shade400,
    'İkindi': Colors.yellow.shade600,
    'Akşam': Colors.red.shade400,
    'Yatsı': Colors.indigo.shade500,
  };

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

      if (todaysPrayer != null) {
        setState(() {
          _todaysPrayerTimes = todaysPrayer;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading prayer times: $e');
    }
  }

  void _startTimer() {
    if (_todaysPrayerTimes == null) return;

    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
    
    _updateCountdown();
  }

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
    String nextPrayerTime = '';

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
          nextPrayerTime = prayer['time']!;
          break;
        }
      }
    }

    // If no prayer found for today, get tomorrow's first prayer
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
        nextPrayerTime = _todaysPrayerTimes!.imsak;
      }
    }

    if (nextPrayerDateTime == null) {
      setState(() {
        _timeUntilNextPrayer = '00:00:00';
        _nextPrayerName = 'Bilinmiyor';
        _nextPrayerTime = '';
        _progressPercent = 0.0;
      });
      return;
    }

    final difference = nextPrayerDateTime.difference(now);
    
    if (difference.isNegative) {
      setState(() {
        _timeUntilNextPrayer = '00:00:00';
        _nextPrayerName = nextPrayerName;
        _nextPrayerTime = nextPrayerTime;
        _progressPercent = 0.0;
      });
      return;
    }

    final totalMinutes = difference.inMinutes;
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    // Calculate progress (assuming 5 hours between prayers as max)
    final maxMinutes = 5 * 60; // 5 hours
    final progress = 1.0 - (totalMinutes / maxMinutes).clamp(0.0, 1.0);

    setState(() {
      _timeUntilNextPrayer = 
          '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
      _nextPrayerName = nextPrayerName;
      _nextPrayerTime = nextPrayerTime;
      _progressPercent = progress;
    });
  }

  Color _getPrayerColor() {
    final cleanName = _nextPrayerName.replaceAll(' (Yarın)', '');
    return _prayerColors[cleanName] ?? Colors.blue.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prayerColor = _getPrayerColor();

    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  prayerColor.withOpacity(0.1),
                  prayerColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: prayerColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: prayerColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: prayerColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sonraki Namaz',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Circular Progress with Timer
                        Row(
                          children: [
                            // Circular Progress
                            CircularPercentIndicator(
                              radius: 60,
                              lineWidth: 8,
                              percent: _progressPercent,
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getIconForPrayer(_nextPrayerName),
                                    color: prayerColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _nextPrayerTime,
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: prayerColor,
                                    ),
                                  ),
                                ],
                              ),
                              progressColor: prayerColor,
                              backgroundColor: prayerColor.withOpacity(0.2),
                              circularStrokeCap: CircularStrokeCap.round,
                            ),
                            
                            const SizedBox(width: 20),
                            
                            // Prayer Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nextPrayerName,
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: prayerColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: prayerColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: prayerColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _timeUntilNextPrayer,
                                      style: GoogleFonts.ebGaramond(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: prayerColor,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'kaldı',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 14,
                                      color: isDark 
                                          ? Colors.white70 
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForPrayer(String prayerName) {
    final cleanName = prayerName.replaceAll(' (Yarın)', '');
    switch (cleanName) {
      case 'İmsak':
        return Icons.wb_twilight;
      case 'Güneş':
        return Icons.wb_sunny;
      case 'Öğle':
        return Icons.light_mode;
      case 'İkindi':
        return Icons.sunny;
      case 'Akşam':
        return Icons.nights_stay;
      case 'Yatsı':
        return Icons.dark_mode;
      default:
        return Icons.access_time;
    }
  }
}
