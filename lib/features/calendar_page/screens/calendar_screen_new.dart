import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/daily_content_model.dart';
import '../../../services/calendar_service.dart';
import '../../../services/database_helper.dart';

class CalendarScreenNew extends StatefulWidget {
  const CalendarScreenNew({super.key});

  @override
  State<CalendarScreenNew> createState() => _CalendarScreenNewState();
}

class _CalendarScreenNewState extends State<CalendarScreenNew> {
  // Data and loading state
  bool _isLoading = true;
  List<DailyContentModel> _calendarData = [];
  
  // PageView controller
  late PageController _pageController;
  int _currentPageIndex = 0;
  
  // Favorite state
  bool _isCurrentPageFavorited = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load calendar data and initialize PageController
  Future<void> _loadData() async {
    try {
      final calendarData = await CalendarService.loadCalendarData();
      final todayIndex = _calculateTodayIndex(calendarData);

      setState(() {
        _calendarData = calendarData;
        _currentPageIndex = todayIndex;
        _isLoading = false;
      });

      // Initialize PageController after data is loaded
      _pageController = PageController(initialPage: todayIndex);
      
      // Check favorite status for initial page
      _checkPageFavorites();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calculate today's index in the calendar data
  int _calculateTodayIndex(List<DailyContentModel> calendarData) {
    if (calendarData.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (int i = 0; i < calendarData.length; i++) {
      try {
        final data = calendarData[i];
        final parts = data.tarih.split(' ');
        
        if (parts.length >= 3) {
          final day = int.parse(parts[0]);
          final monthStr = parts[1];
          final year = int.parse(parts[2]);
          
          const monthMap = {
            'OCAK': 1, 'ŞUBAT': 2, 'MART': 3, 'NİSAN': 4,
            'MAYIS': 5, 'HAZİRAN': 6, 'TEMMUZ': 7, 'AĞUSTOS': 8,
            'EYLÜL': 9, 'EKİM': 10, 'KASIM': 11, 'ARALIK': 12,
          };
          
          final month = monthMap[monthStr];
          if (month != null) {
            final dataDate = DateTime(year, month, day);
            if (dataDate.isAtSameMomentAs(today)) {
              return i;
            }
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    return calendarData.length > 100 ? 100 : 0;
  }

  @override
  void dispose() {
    if (!_isLoading && _calendarData.isNotEmpty) {
      _pageController.dispose();
    }
    super.dispose();
  }

  /// Get formatted date information for the current page
  Map<String, dynamic> _getFormattedDates(int pageIndex) {
    if (_calendarData.isEmpty || pageIndex >= _calendarData.length || pageIndex < 0) {
      return {
        'gregorian': {'day': '', 'month': '', 'year': '', 'weekday': ''},
        'hijri': {'day': '', 'month': '', 'year': ''},
      };
    }

    final currentData = _calendarData[pageIndex];

    try {
      final parts = currentData.tarih.split(' ');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1];
        final year = int.parse(parts[2]);

        const monthMap = {
          'OCAK': 1, 'ŞUBAT': 2, 'MART': 3, 'NİSAN': 4,
          'MAYIS': 5, 'HAZİRAN': 6, 'TEMMUZ': 7, 'AĞUSTOS': 8,
          'EYLÜL': 9, 'EKİM': 10, 'KASIM': 11, 'ARALIK': 12,
        };

        final month = monthMap[monthStr] ?? 1;
        final date = DateTime(year, month, day);

        final dayFormatter = DateFormat('d', 'tr_TR');
        final monthFormatter = DateFormat('MMMM', 'tr_TR');
        final yearFormatter = DateFormat('yyyy', 'tr_TR');
        final weekdayFormatter = DateFormat('EEEE', 'tr_TR');

        final hijriDate = _calculateHijriDate(date);

        return {
          'gregorian': {
            'day': dayFormatter.format(date),
            'month': monthFormatter.format(date),
            'year': yearFormatter.format(date),
            'weekday': weekdayFormatter.format(date),
          },
          'hijri': {
            'day': hijriDate['day'].toString(),
            'month': hijriDate['month'],
            'year': hijriDate['year'].toString(),
          },
        };
      }
    } catch (e) {
      print('Date parsing error: $e');
    }

    return {
      'gregorian': {'day': '1', 'month': 'Ocak', 'year': '2025', 'weekday': 'Çarşamba'},
      'hijri': {'day': '1', 'month': 'Recep', 'year': '1446'},
    };
  }

  /// Calculate Hijri date with Turkish month names
  Map<String, dynamic> _calculateHijriDate(DateTime gregorianDate) {
    final hijriEpoch = DateTime(622, 7, 16);
    final daysDifference = gregorianDate.difference(hijriEpoch).inDays;
    final hijriYear = (daysDifference / 354.367).floor() + 1;
    
    final yearStart = hijriEpoch.add(Duration(days: ((hijriYear - 1) * 354.367).round()));
    final daysIntoYear = gregorianDate.difference(yearStart).inDays;
    final hijriMonth = (daysIntoYear / 29.53).floor() + 1;
    final monthStart = yearStart.add(Duration(days: ((hijriMonth - 1) * 29.53).round()));
    final hijriDay = gregorianDate.difference(monthStart).inDays + 1;

    return {
      'day': hijriDay.clamp(1, 30),
      'month': _getHijriMonthNameTurkish(hijriMonth.clamp(1, 12)),
      'year': hijriYear,
    };
  }

  /// Get Hijri month name in Turkish
  String _getHijriMonthNameTurkish(int month) {
    const hijriMonths = [
      'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir', 
      'Cemayizelevvel', 'Cemayizelahir', 'Recep', 'Şaban',
      'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce',
    ];

    if (month >= 1 && month <= 12) {
      return hijriMonths[month - 1];
    }
    return 'Bilinmeyen';
  }

  /// Check favorite status for current page
  Future<void> _checkPageFavorites() async {
    if (_calendarData.isNotEmpty && 
        _currentPageIndex >= 0 && 
        _currentPageIndex < _calendarData.length) {
      
      try {
        final currentData = _calendarData[_currentPageIndex];
        final hasFavorites = await DatabaseHelper.instance.hasPageFavorites(currentData.tarih);
        
        if (mounted) {
          setState(() {
            _isCurrentPageFavorited = hasFavorites;
          });
        }
      } catch (e) {
        print('Error checking favorites: $e');
        if (mounted) {
          setState(() {
            _isCurrentPageFavorited = false;
          });
        }
      }
    }
  }

  /// Handle page changes
  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    _checkPageFavorites();
  }

  /// Build date header
  Widget _buildDateHeader(int pageIndex) {
    final dates = _getFormattedDates(pageIndex);
    final gregorian = dates['gregorian'];
    final hijri = dates['hijri'];

    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade600, Colors.brown.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gregorian Date
                Row(
                  children: [
                    Text(
                      gregorian['day'],
                      style: GoogleFonts.ebGaramond(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gregorian['month'],
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          gregorian['year'],
                          style: GoogleFonts.ebGaramond(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  gregorian['weekday'],
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                // Hijri Date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${hijri['day']} ${hijri['month']} ${hijri['year']}',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Favorite button
          Positioned(
            top: 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isCurrentPageFavorited ? Icons.favorite : Icons.favorite_border,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build page content
  Widget _buildPageContent(int pageIndex) {
    if (_calendarData.isEmpty || pageIndex >= _calendarData.length || pageIndex < 0) {
      return const Expanded(
        child: Center(child: Text('Veri bulunamadı')),
      );
    }

    final currentData = _calendarData[pageIndex];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risale-i Nur Vecizesi
              if (currentData.risaleINur.vecize.isNotEmpty) ...[
                Text(
                  'Risale-i Nur',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.brown.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentData.risaleINur.vecize,
                        style: GoogleFonts.merriweather(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.brown.shade800,
                        ),
                      ),
                      if (currentData.risaleINur.kaynak.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '— ${currentData.risaleINur.kaynak}',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.brown.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Ayet/Hadis
              if (currentData.ayetHadis.metin.isNotEmpty) ...[
                Text(
                  'Ayet/Hadis',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentData.ayetHadis.metin,
                        style: GoogleFonts.merriweather(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.green.shade800,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      if (currentData.ayetHadis.kaynak.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '— ${currentData.ayetHadis.kaynak}',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Tarihte Bugün
              if (currentData.tariheBugun.isNotEmpty) ...[
                Text(
                  'Tarihte Bugün',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    currentData.tariheBugun,
                    style: GoogleFonts.merriweather(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Akşam Yemeği
              if (currentData.aksamYemegi.isNotEmpty) ...[
                Text(
                  'Akşam Yemeği',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    currentData.aksamYemegi,
                    style: GoogleFonts.merriweather(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFF1EAD9), Colors.brown.shade50],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Takvim yükleniyor...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_calendarData.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFF1EAD9), Colors.brown.shade50],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48),
                SizedBox(height: 16),
                Text('Veri yüklenemedi. Lütfen tekrar deneyin.'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFF1EAD9), Colors.brown.shade50],
          ),
        ),
        child: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _calendarData.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  _buildDateHeader(index),
                  _buildPageContent(index),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
