import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/daily_content_model.dart';
import '../../../models/prayer_times_model.dart';
import '../../../services/calendar_service.dart';
import '../../../services/prayer_api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  // Loading state
  bool _isLoading = true;
  List<DailyContentModel> _calendarData = [];
  PrayerTimesModel? _prayerTimes;
  
  // Current day navigation
  int _currentPageIndex = 0;
  
  // Page flip controller
  late AnimationController _pageTurnController;
  late Animation<double> _pageTurnAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize page turn controller
    _pageTurnController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pageTurnAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTurnController,
      curve: Curves.easeInOut,
    ));
    
    _loadData();
  }

  /// Load both calendar data and prayer times
  Future<void> _loadData() async {
    try {
      // Load data in parallel for better performance
      final futures = await Future.wait([
        CalendarService.loadCalendarData(),
        PrayerApiService.getPrayerTimesForToday('Ankara'),
      ]);

      final calendarData = futures[0] as List<DailyContentModel>;
      final prayerTimes = futures[1] as PrayerTimesModel;

      setState(() {
        _calendarData = calendarData;
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageTurnController.dispose();
    super.dispose();
  }

  /// Get formatted date information for the current page
  Map<String, String> _getFormattedDates() {
    if (_calendarData.isEmpty) return {'gregorian': '', 'hijri': ''};
    
    final currentData = _calendarData[_currentPageIndex];
    
    // Parse the Gregorian date from the data
    try {
      final parts = currentData.miladiTarih.split(' ');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1];
        final year = int.parse(parts[2]);
        
        // Turkish month names to numbers
        const monthMap = {
          'OCAK': 1, 'ŞUBAT': 2, 'MART': 3, 'NİSAN': 4,
          'MAYIS': 5, 'HAZİRAN': 6, 'TEMMUZ': 7, 'AĞUSTOS': 8,
          'EYLÜL': 9, 'EKİM': 10, 'KASIM': 11, 'ARALIK': 12
        };
        
        final month = monthMap[monthStr] ?? 1;
        final date = DateTime(year, month, day);
        
        // Format Gregorian date
        final formatter = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');
        final gregorianFormatted = formatter.format(date).toUpperCase();
        
        // Use a simple hijri date format (placeholder for now)
        final hijriFormatted = '${day} ${_getHijriMonthName(month)} ${year}'; // Simple placeholder
        
        return {
          'gregorian': gregorianFormatted,
          'hijri': hijriFormatted,
        };
      }
    } catch (e) {
      print('Date parsing error: $e');
    }
    
    // Fallback to original data
    return {
      'gregorian': currentData.miladiTarih,
      'hijri': 'Hijri Tarih', // Simple fallback
    };
  }

  /// Get Hijri month name in Turkish
  String _getHijriMonthName(int month) {
    const hijriMonths = [
      'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir',
      'Cemaziyelevvel', 'Cemaziyelahir', 'Recep', 'Şaban',
      'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce'
    ];
    
    if (month >= 1 && month <= 12) {
      return hijriMonths[month - 1];
    }
    return 'Bilinmeyen';
  }

  /// Handle vertical drag end for page flip gesture
  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    // If fast upward swipe, trigger page flip
    if (velocity < -250) {
      if (_isFlipped) {
        _pageTurnController.reverse();
      } else {
        _pageTurnController.forward();
      }
      setState(() {
        _isFlipped = !_isFlipped;
      });
    }
  }

  /// Navigate to previous day
  void _goToPreviousDay() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
        _isFlipped = false;
      });
      _pageTurnController.reset();
    }
  }

  /// Navigate to next day
  void _goToNextDay() {
    if (_currentPageIndex < _calendarData.length - 1) {
      setState(() {
        _currentPageIndex++;
        _isFlipped = false;
      });
      _pageTurnController.reset();
    }
  }

  /// Build the prominent date header
  Widget _buildDateHeader() {
    final dates = _getFormattedDates();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade600, Colors.brown.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.shade300.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gregorian Date
          Text(
            dates['gregorian']!,
            style: GoogleFonts.ebGaramond(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Hijri Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dates['hijri']!,
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation buttons row
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous Day Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentPageIndex > 0 ? _goToPreviousDay : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Önceki Gün'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Day Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.brown.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.shade300),
            ),
            child: Text(
              '${_currentPageIndex + 1} / ${_calendarData.length}',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Next Day Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentPageIndex < _calendarData.length - 1 ? _goToNextDay : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Sonraki Gün'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build page content with flip animation
  Widget _buildPageContent() {
    if (_calendarData.isEmpty) return const SizedBox();
    
    final currentData = _calendarData[_currentPageIndex];
    
    return Expanded(
      child: GestureDetector(
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _pageTurnAnimation,
              builder: (context, child) {
                final isShowingFront = _pageTurnAnimation.value < 0.5;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_pageTurnAnimation.value * 3.14159),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: isShowingFront
                        ? _buildFrontPage(currentData)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(3.14159),
                            child: _buildBackPage(currentData),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build front page content
  Widget _buildFrontPage(DailyContentModel data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prayer times section
          if (_prayerTimes != null) _buildPrayerTimesSection(_prayerTimes!),
          if (_prayerTimes != null) const SizedBox(height: 16),
          
          // Historical event section
          _buildHistoricalEventSection(data),
          const SizedBox(height: 16),
          
          // Risale quote section
          _buildRisaleQuoteSection(data),
          const SizedBox(height: 20),
          
          // Flip instruction
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_up, color: Colors.amber.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Sayfayı çevirmek için yukarı kaydırın',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build back page content
  Widget _buildBackPage(DailyContentModel data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse/Hadith section
          _buildVerseHadithSection(data),
          const SizedBox(height: 16),
          
          // Daily menu section
          _buildDailyMenuSection(data),
          const SizedBox(height: 20),
          
          // Flip back instruction
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_up, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Ön sayfaya dönmek için yukarı kaydırın',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build historical event section
  Widget _buildHistoricalEventSection(DailyContentModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.brown.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tarihte Bugün (${data.frontPage.historicalEvent.year})',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.frontPage.historicalEvent.event,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              height: 1.5,
              color: Colors.brown.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Risale quote section
  Widget _buildRisaleQuoteSection(DailyContentModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Risale-i Nur\'dan',
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${data.frontPage.risaleQuote.text}"',
            style: GoogleFonts.ebGaramond(
              fontSize: 15,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${data.frontPage.risaleQuote.source}',
              style: GoogleFonts.ebGaramond(
                fontSize: 13,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build verse/hadith section
  Widget _buildVerseHadithSection(DailyContentModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.backPage.dailyVerseOrHadith.type,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.backPage.dailyVerseOrHadith.text,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              height: 1.5,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${data.backPage.dailyVerseOrHadith.source}',
              style: GoogleFonts.ebGaramond(
                fontSize: 13,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build daily menu section
  Widget _buildDailyMenuSection(DailyContentModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.purple.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Günün Menüsü',
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMenuRow('🍲 Çorba', data.backPage.dailyMenu.soup),
          const SizedBox(height: 8),
          _buildMenuRow('🍽️ Ana Yemek', data.backPage.dailyMenu.mainCourse),
          const SizedBox(height: 8),
          _buildMenuRow('🍰 Tatlı', data.backPage.dailyMenu.dessert),
        ],
      ),
    );
  }

  Widget _buildMenuRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ebGaramond(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.purple.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.ebGaramond(
              fontSize: 16,
              color: Colors.purple.shade800,
            ),
          ),
        ),
      ],
    );
  }

  /// Build prayer times section widget
  Widget _buildPrayerTimesSection(PrayerTimesModel prayerTimes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.indigo.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Günün Namaz Vakitleri (Ankara)',
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Prayer times grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPrayerTimeItem('İmsak', prayerTimes.imsak, Colors.indigo.shade600),
              _buildPrayerTimeItem('Güneş', prayerTimes.gunes, Colors.orange.shade600),
              _buildPrayerTimeItem('Öğle', prayerTimes.ogle, Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPrayerTimeItem('İkindi', prayerTimes.ikindi, Colors.brown.shade600),
              _buildPrayerTimeItem('Akşam', prayerTimes.aksam, Colors.deepOrange.shade600),
              _buildPrayerTimeItem('Yatsı', prayerTimes.yatsi, Colors.deepPurple.shade600),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual prayer time item
  Widget _buildPrayerTimeItem(String name, String time, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: GoogleFonts.ebGaramond(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: GoogleFonts.ebGaramond(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while data is being loaded
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF1EAD9),
              Colors.brown.shade50,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state if no data is loaded
    if (_calendarData.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF1EAD9),
              Colors.brown.shade50,
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'Veri yüklenemedi. Lütfen tekrar deneyin.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Main UI with new structure
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF1EAD9),
            Colors.brown.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          // 1. Date Header
          _buildDateHeader(),
          
          // 2. Page Content (Expanded)
          _buildPageContent(),
          
          // 3. Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }
}
