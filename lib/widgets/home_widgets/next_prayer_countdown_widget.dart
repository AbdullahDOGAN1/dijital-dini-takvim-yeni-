// ignore_for_file: avoid_print

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
  State<NextPrayerCountdownWidget> createState() =>
      _NextPrayerCountdownWidgetState();
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

        final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);

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
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.grey.shade900, Colors.grey.shade800]
                    : [prayerColor.withOpacity(0.2), prayerColor.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white12 : prayerColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: prayerColor.withOpacity(isDark ? 0.05 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: prayerColor.withOpacity(
                                    isDark ? 0.2 : 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color: prayerColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sonraki Vakit',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Timer Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Circular Progress
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularPercentIndicator(
                                  radius: 60,
                                  lineWidth: 10,
                                  percent: _progressPercent.clamp(0.0, 1.0),
                                  center: Icon(
                                    _getPrayerIcon(_nextPrayerName),
                                    size: 40,
                                    color: prayerColor,
                                  ),
                                  progressColor: prayerColor,
                                  backgroundColor: prayerColor.withOpacity(
                                    isDark ? 0.2 : 0.15,
                                  ),
                                  circularStrokeCap: CircularStrokeCap.round,
                                  animation: false,
                                ),
                              ),

                              // Timer Details
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _nextPrayerName.toUpperCase(),
                                        style: GoogleFonts.ebGaramond(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: prayerColor,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _timeUntilNextPrayer,
                                        style: GoogleFonts.libreBaskerville(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.notifications_active_outlined,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _nextPrayerTime,
                                            style: GoogleFonts.ebGaramond(
                                              fontSize: 16,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }

  // Get matching icon based on prayer
  IconData _getPrayerIcon(String name) {
    switch (name) {
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

  Color _getPrayerColor() {
    if (_nextPrayerName.isEmpty) return Colors.green.shade600;

    // Switch over correct Turkish names
    switch (_nextPrayerName) {
      case 'İmsak':
        return Colors.purple.shade400;
      case 'Güneş':
        return Colors.orange.shade400;
      case 'Öğle':
        return Colors.blue.shade500;
      case 'İkindi':
        return Colors.yellow.shade700;
      case 'Akşam':
        return Colors.red.shade400;
      case 'Yatsı':
        return Colors.indigo.shade400;
      default:
        return _prayerColors[_nextPrayerName] ?? Colors.green.shade600;
    }
  }
}
