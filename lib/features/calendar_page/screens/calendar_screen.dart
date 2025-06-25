import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/daily_content_model.dart';
import '../../../services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  // Loading state
  bool _isLoading = true;
  List<DailyContentModel> _calendarData = [];
  
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

  /// Load calendar data
  Future<void> _loadData() async {
    try {
      final calendarData = await CalendarService.loadCalendarData();

      setState(() {
        _calendarData = calendarData;
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
  Map<String, dynamic> _getFormattedDates() {
    if (_calendarData.isEmpty) return {
      'gregorian': {'day': '', 'month': '', 'year': '', 'weekday': ''},
      'hijri': {'day': '', 'month': '', 'year': ''}
    };
    
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
        
        // Format different parts of Gregorian date
        final dayFormatter = DateFormat('d', 'tr_TR');
        final monthFormatter = DateFormat('MMMM', 'tr_TR');
        final yearFormatter = DateFormat('yyyy', 'tr_TR');
        final weekdayFormatter = DateFormat('EEEE', 'tr_TR');
        
        // Calculate approximate Hijri date (basic conversion)
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
          }
        };
      }
    } catch (e) {
      print('Date parsing error: $e');
    }
    
    // Fallback to original data
    return {
      'gregorian': {
        'day': '1',
        'month': 'Ocak',
        'year': '2025',
        'weekday': 'Çarşamba',
      },
      'hijri': {
        'day': '1',
        'month': 'Recep',
        'year': '1446',
      }
    };
  }

  /// Calculate approximate Hijri date from Gregorian date
  Map<String, dynamic> _calculateHijriDate(DateTime gregorianDate) {
    // Basic conversion using epoch dates
    // Hijri year 1 started on July 16, 622 CE
    final hijriEpoch = DateTime(622, 7, 16);
    final daysDifference = gregorianDate.difference(hijriEpoch).inDays;
    
    // Average Hijri year is about 354.367 days
    final hijriYear = (daysDifference / 354.367).floor() + 1;
    
    // Calculate approximate month and day (simplified)
    final yearStart = hijriEpoch.add(Duration(days: ((hijriYear - 1) * 354.367).floor()));
    final daysIntoYear = gregorianDate.difference(yearStart).inDays;
    final hijriMonth = (daysIntoYear / 29.53).floor() + 1;
    final hijriDay = (daysIntoYear % 29.53).floor() + 1;
    
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

  /// Build the prominent date header with rich hierarchical display
  Widget _buildDateHeader() {
    final dates = _getFormattedDates();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade600, Colors.brown.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.shade300.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.brown.shade400.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Gregorian Date - Hierarchical Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large Day Number
              Text(
                dates['gregorian']['day'],
                style: GoogleFonts.ebGaramond(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              // Month and Year Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dates['gregorian']['month'].toUpperCase(),
                    style: GoogleFonts.ebGaramond(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    dates['gregorian']['year'],
                    style: GoogleFonts.ebGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Weekday
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dates['gregorian']['weekday'].toUpperCase(),
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85),
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Elegant Hijri Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.brightness_2,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${dates['hijri']['day']} ${dates['hijri']['month']} ${dates['hijri']['year']}',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation buttons row with proper theming
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Previous Day Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentPageIndex > 0 ? _goToPreviousDay : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.brown.shade400.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Önceki',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Day Counter with better styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.brown.shade100, Colors.brown.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.shade200.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_currentPageIndex + 1} / ${_calendarData.length}',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Next Day Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentPageIndex < _calendarData.length - 1 ? _goToNextDay : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.brown.shade400.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sonraki',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            ],
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main page content
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onVerticalDragEnd: _onVerticalDragEnd,
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
            
            // Page flip indicator at bottom
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown.shade600.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    if (_isFlipped) {
                      _pageTurnController.reverse();
                    } else {
                      _pageTurnController.forward();
                    }
                    setState(() {
                      _isFlipped = !_isFlipped;
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _pageTurnAnimation,
                    builder: (context, child) {
                      return Icon(
                        _pageTurnAnimation.value < 0.5 
                          ? Icons.flip_to_back 
                          : Icons.flip_to_front,
                        size: 20,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build front page content (ÖN SAYFA: Önemli Olay + Risale-i Nur)
  Widget _buildFrontPage(DailyContentModel data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.brown.shade50,
            Colors.amber.shade50,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Historical Event Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade100.withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.brown.shade200.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.brown.shade600, Colors.brown.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.shade400.withOpacity(0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tarihte Bugün (${data.frontPage.historicalEvent.year})',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.frontPage.historicalEvent.event,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.brown.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Risale-i Nur Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100.withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade600, Colors.green.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade400.withOpacity(0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Risale-i Nur\'dan',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade100, width: 1),
                    ),
                    child: Text(
                      '"${data.frontPage.risaleQuote.text}"',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200, width: 1),
                      ),
                      child: Text(
                        '— ${data.frontPage.risaleQuote.source}',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 13,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 80), // Space for flip button
          ],
        ),
      ),
    );
  }

  /// Build back page content (ARKA SAYFA: Hadis/Ayet + Yemek Menüsü)
  Widget _buildBackPage(DailyContentModel data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hadis/Ayet Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade400.withOpacity(0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.backPage.dailyVerseOrHadith.type,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100, width: 1),
                    ),
                    child: Text(
                      data.backPage.dailyVerseOrHadith.text,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                      ),
                      child: Text(
                        '— ${data.backPage.dailyVerseOrHadith.source}',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Daily Menu Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.shade100.withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.purple.shade200.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade600, Colors.purple.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade400.withOpacity(0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Günün Menüsü',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMenuRow('🍲 Çorba', data.backPage.dailyMenu.soup),
                  const SizedBox(height: 10),
                  _buildMenuRow('🍽️ Ana Yemek', data.backPage.dailyMenu.mainCourse),
                  const SizedBox(height: 10),
                  _buildMenuRow('🍰 Tatlı', data.backPage.dailyMenu.dessert),
                ],
              ),
            ),
            
            const SizedBox(height: 80), // Space for flip button
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ebGaramond(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ebGaramond(
                fontSize: 15,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
    return Scaffold(
      body: Container(
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
        child: SafeArea(
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
        ),
      ),
    );
  }
}
