import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/prayer_times_model.dart';
import '../../../services/prayer_api_service.dart';

class PrayerTimesListScreen extends StatefulWidget {
  const PrayerTimesListScreen({super.key});

  @override
  State<PrayerTimesListScreen> createState() => _PrayerTimesListScreenState();
}

class _PrayerTimesListScreenState extends State<PrayerTimesListScreen> {
  PrayerTimesModel? _prayerTimes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final prayerTimes = await PrayerApiService.getPrayerTimesForToday('Ankara');
      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading prayer times: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.indigo.shade50, Colors.purple.shade50],
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prayerTimes == null
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
                        'Namaz vakitleri yüklenemedi',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 20,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade600, Colors.purple.shade600],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Namaz Vakitleri',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Ankara - Bugün',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Prayer times list
                      ..._buildPrayerTimesList(_prayerTimes!),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildPrayerTimesList(PrayerTimesModel prayerTimes) {
    final prayers = [
      {'name': 'İmsak', 'time': prayerTimes.imsak, 'icon': Icons.nightlight_round, 'color': Colors.indigo},
      {'name': 'Güneş', 'time': prayerTimes.gunes, 'icon': Icons.wb_sunny, 'color': Colors.orange},
      {'name': 'Öğle', 'time': prayerTimes.ogle, 'icon': Icons.wb_sunny_outlined, 'color': Colors.amber},
      {'name': 'İkindi', 'time': prayerTimes.ikindi, 'icon': Icons.wb_twilight, 'color': Colors.brown},
      {'name': 'Akşam', 'time': prayerTimes.aksam, 'icon': Icons.wb_twilight, 'color': Colors.deepOrange},
      {'name': 'Yatsı', 'time': prayerTimes.yatsi, 'icon': Icons.nights_stay, 'color': Colors.deepPurple},
    ];

    return prayers.map((prayer) {
      final color = prayer['color'] as MaterialColor;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              prayer['icon'] as IconData,
              color: color.shade600,
              size: 24,
            ),
          ),
          title: Text(
            prayer['name'] as String,
            style: GoogleFonts.ebGaramond(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          subtitle: Text(
            'Namaz Vakti',
            style: GoogleFonts.ebGaramond(
              fontSize: 14,
              color: color.shade500,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.shade200),
            ),
            child: Text(
              prayer['time'] as String,
              style: GoogleFonts.ebGaramond(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
