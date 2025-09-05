import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/daily_content_model.dart';
import '../../../services/calendar_service.dart';
import '../../../services/database_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  // Loading state
  bool _isLoading = true;
  List<DailyContentModel> _calendarData = [];

  // Current day navigation
  int _currentPageIndex = 0;
  
  // Favorite state for current page
  bool _isCurrentPageFavorited = false;

  // Page flip controller
  late AnimationController _pageTurnController;
  late Animation<double> _pageTurnAnimation;
  bool _isFlipped = false;

  // Cache for formatted dates to prevent recalculation
  Map<int, Map<String, dynamic>> _datesCache = {};
  
  // Debounce timer for rapid page changes
  Timer? _debounceTimer;

  // Visual stability flags
  bool _isTransitioning = false;
  int? _targetPageIndex;
  
  // Initial load stability
  bool _isInitialLoad = true;
  bool _hasCompletedFirstRender = false;

  @override
  void initState() {
    super.initState();

    // Initialize page turn controller
    _pageTurnController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pageTurnAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageTurnController, curve: Curves.easeInOut),
    );

    // Load data with initial stability
    _initializeStably();
  }

  /// Initialize with stability checks for first load
  Future<void> _initializeStably() async {
    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
    });

    // Small delay to ensure widget is mounted
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    
    await _loadData();
    
    // Mark initial load as complete after a small delay
    if (mounted) {
      Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isInitialLoad = false;
            _hasCompletedFirstRender = true;
          });
        }
      });
    }
  }

  /// Load calendar data and initialize to today's date
  Future<void> _loadData() async {
    try {
      final calendarData = await CalendarService.loadCalendarData();

      if (!mounted) return;

      // Calculate today's index before setting state
      final todayIndex = _calculateTodayIndex(calendarData);

      // Set state with all data at once to prevent flickering
      setState(() {
        _calendarData = calendarData;
        _currentPageIndex = todayIndex; // Start from today instead of 0
        _isLoading = false;
      });
      
      // Small delay before cache operations to ensure UI is stable
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Pre-cache today's date to prevent calculation delay
      _getFormattedDates();
      
      // Check favorite status for initial page (debounced)
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          _checkPageFavorites();
        }
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Calculate today's index in the calendar data
  int _calculateTodayIndex(List<DailyContentModel> calendarData) {
    if (calendarData.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Find today's date in the calendar data
    for (int i = 0; i < calendarData.length; i++) {
      try {
        final data = calendarData[i];
        final parts = data.tarih.split(' ');
        
        if (parts.length >= 3) {
          final day = int.parse(parts[0]);
          final monthStr = parts[1];
          final year = int.parse(parts[2]);
          
          // Turkish month names to numbers
          const monthMap = {
            'OCAK': 1, 'ŞUBAT': 2, 'MART': 3, 'NİSAN': 4,
            'MAYIS': 5, 'HAZİRAN': 6, 'TEMMUZ': 7, 'AĞUSTOS': 8,
            'EYLÜL': 9, 'EKİM': 10, 'KASIM': 11, 'ARALIK': 12,
          };
          
          final month = monthMap[monthStr];
          if (month != null) {
            final dataDate = DateTime(year, month, day);
            
            if (dataDate.isAtSameMomentAs(today)) {
              return i; // Found today's index
            }
          }
        }
      } catch (e) {
        // Continue searching if parsing fails
        continue;
      }
    }
    
    // If today is not found, return the middle of the data or 0
    return calendarData.length > 100 ? 100 : 0;
  }

  @override
  void dispose() {
    _pageTurnController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Get formatted date information for the current page with enhanced stability
  Map<String, dynamic> _getFormattedDates() {
    // Validate index first with comprehensive checks
    if (_calendarData.isEmpty || 
        _currentPageIndex >= _calendarData.length || 
        _currentPageIndex < 0 ||
        _isTransitioning) {
      return {
        'gregorian': {'day': '', 'month': '', 'year': '', 'weekday': ''},
        'hijri': {'day': '', 'month': '', 'year': ''},
      };
    }

    // During initial load, force fresh calculation
    if (_isInitialLoad || !_hasCompletedFirstRender) {
      // Don't use cache during initial stabilization
    } else {
      // Check cache first for stable states
      if (_datesCache.containsKey(_currentPageIndex)) {
        return _datesCache[_currentPageIndex]!;
      }
    }

    final currentData = _calendarData[_currentPageIndex];

    // Parse the Gregorian date from the data with enhanced error handling
    try {
      final parts = currentData.tarih.split(' ');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1];
        final year = int.parse(parts[2]);

        // Turkish month names to numbers
        const monthMap = {
          'OCAK': 1, 'ŞUBAT': 2, 'MART': 3, 'NİSAN': 4,
          'MAYIS': 5, 'HAZİRAN': 6, 'TEMMUZ': 7, 'AĞUSTOS': 8,
          'EYLÜL': 9, 'EKİM': 10, 'KASIM': 11, 'ARALIK': 12,
        };

        final month = monthMap[monthStr] ?? 1;
        final date = DateTime(year, month, day);

        // Format different parts of Gregorian date
        final dayFormatter = DateFormat('d', 'tr_TR');
        final monthFormatter = DateFormat('MMMM', 'tr_TR');
        final yearFormatter = DateFormat('yyyy', 'tr_TR');
        final weekdayFormatter = DateFormat('EEEE', 'tr_TR');

        // Calculate enhanced Hijri date
        final hijriDate = _calculateHijriDate(date);

        final formattedDates = {
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

        // Cache the result only if we're in stable state
        if (!_isTransitioning && _hasCompletedFirstRender) {
          _datesCache[_currentPageIndex] = formattedDates;
          
          // More aggressive cache size limiting for stability
          if (_datesCache.length > 5) {
            // Keep only the most recent 3 entries
            final sortedKeys = _datesCache.keys.toList()..sort();
            while (_datesCache.length > 3) {
              _datesCache.remove(sortedKeys.removeAt(0));
            }
          }
        }
        
        return formattedDates;
      }
    } catch (e) {
      print('Date parsing error: $e');
    }

    // Fallback to original data
    final fallbackDates = {
      'gregorian': {
        'day': '1',
        'month': 'Ocak',
        'year': '2025',
        'weekday': 'Çarşamba',
      },
      'hijri': {'day': '1', 'month': 'Recep', 'year': '1446'},
    };
    
    // Cache fallback too
    _datesCache[_currentPageIndex] = fallbackDates;
    return fallbackDates;
  }

  /// Calculate approximate Hijri date from Gregorian date
  Map<String, dynamic> _calculateHijriDate(DateTime gregorianDate) {
    // More accurate conversion using epoch dates
    // Hijri year 1 started on July 16, 622 CE
    final hijriEpoch = DateTime(622, 7, 16);
    final daysDifference = gregorianDate.difference(hijriEpoch).inDays;

    // More accurate average Hijri year is about 354.367 days
    final hijriYear = (daysDifference / 354.367).floor() + 1;

    // Calculate approximate month and day with better accuracy
    final yearStart = hijriEpoch.add(
      Duration(days: ((hijriYear - 1) * 354.367).round()),
    );
    final daysIntoYear = gregorianDate.difference(yearStart).inDays;
    
    // Better month calculation
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
      'Muharrem',
      'Safer',
      'Rebiülevvel',
      'Rebiülahir', 
      'Cemayizelevvel',
      'Cemayizelahir',
      'Recep',
      'Şaban',
      'Ramazan',
      'Şevval',
      'Zilkade',
      'Zilhicce',
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

  /// Navigate to previous day with enhanced stability
  void _goToPreviousDay() {
    if (_currentPageIndex > 0 && 
        !_isTransitioning && 
        !_isInitialLoad && 
        _hasCompletedFirstRender && 
        _calendarData.isNotEmpty) {
      _performPageTransition(_currentPageIndex - 1);
    }
  }

  /// Navigate to next day with enhanced stability
  void _goToNextDay() {
    if (_currentPageIndex < _calendarData.length - 1 && 
        !_isTransitioning && 
        !_isInitialLoad && 
        _hasCompletedFirstRender && 
        _calendarData.isNotEmpty) {
      _performPageTransition(_currentPageIndex + 1);
    }
  }

  /// Perform smooth page transition with loading state
  void _performPageTransition(int targetIndex) {
    // Validate target index
    if (targetIndex < 0 || targetIndex >= _calendarData.length) {
      return;
    }

    // Cancel any pending operations
    _debounceTimer?.cancel();
    
    // Aggressive cache clearing for stability
    _datesCache.clear();
    
    // Set transitioning state immediately
    setState(() {
      _isTransitioning = true;
      _targetPageIndex = targetIndex;
    });

    // Longer transition delay for stability
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _currentPageIndex = targetIndex;
          _isFlipped = false;
        });
        
        _pageTurnController.reset();

        // Complete transition after longer delay for UI stability
        Timer(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _isTransitioning = false;
              _targetPageIndex = null;
            });
            
            // Debounced operations for stability
            _debounceTimer = Timer(const Duration(milliseconds: 200), () {
              if (mounted) {
                // Cache the new date and check favorites
                _getFormattedDates();
                _checkPageFavorites();
              }
            });
          }
        });
      }
    });
  }

  /// Build the prominent date header with enhanced stability
  Widget _buildDateHeader() {
    // Show transitioning state if in transition
    if (_isTransitioning && _targetPageIndex != null) {
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
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tarih güncelleniyor...',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading during initial load or if still stabilizing
    if (_isInitialLoad || !_hasCompletedFirstRender) {
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
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Yükleniyor...',
                style: GoogleFonts.ebGaramond(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Prevent building if data is not ready or indices are invalid
    if (_calendarData.isEmpty || 
        _currentPageIndex >= _calendarData.length || 
        _currentPageIndex < 0) {
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
        child: Center(
          child: Text(
            'Takvim yükleniyor...',
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Get dates for current page index
    final dates = _getFormattedDates();

    return Stack(
      children: [
        Container(
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
    ),
        
        // Favorite button in top-right corner
        Positioned(
          top: 8,
          right: 16,
          child: GestureDetector(
            onLongPress: () {
              // Show save favorite dialog on long press
              if (_calendarData.isNotEmpty) {
                _showSaveFavoriteDialog(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isCurrentPageFavorited ? Icons.favorite : Icons.favorite_border,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
          ),
        ),
      ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
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
                  onPressed: _currentPageIndex < _calendarData.length - 1
                      ? _goToNextDay
                      : null,
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

  /// Build page content with enhanced stability and transition handling
  Widget _buildPageContent() {
    // Show transition state or initial loading
    if (_isTransitioning || _isInitialLoad || !_hasCompletedFirstRender) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.brown.shade600),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isInitialLoad || !_hasCompletedFirstRender 
                    ? 'Yükleniyor...' 
                    : 'İçerik güncelleniyor...',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 16,
                    color: Colors.brown.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Validate data and indices
    if (_calendarData.isEmpty || 
        _currentPageIndex >= _calendarData.length || 
        _currentPageIndex < 0) {
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
          child: Center(
            child: Text(
              'İçerik Yükleniyor...',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                color: Colors.brown.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

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
                        decoration: const BoxDecoration(color: Colors.white),
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
          colors: [Colors.brown.shade50, Colors.amber.shade50],
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
                  // Üst sıra - Başlık
                  Row(
                    children: [
                      // Başlık kısmı
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.brown.shade600,
                              Colors.brown.shade700,
                            ],
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
                          'Tarihte Bugün',
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
                    data.tariheBugun,
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
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade700,
                            ],
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
                      border: Border.all(
                        color: Colors.green.shade100,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '"${data.risaleINur.vecize}"',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '— ${data.risaleINur.kaynak}',
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
          colors: [Colors.blue.shade50, Colors.purple.shade50],
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
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade700,
                            ],
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
                        child: Icon(Icons.book, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ayet/Hadis',
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
                      data.ayetHadis.metin,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '— ${data.ayetHadis.kaynak}',
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

            // Daily Menu Section (Simplified for model compatibility)
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
                            colors: [
                              Colors.purple.shade600,
                              Colors.purple.shade700,
                            ],
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
                        'Akşam Yemeği',
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
                  Container(
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
                          '🍽️ ',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.aksamYemegi,
                            style: GoogleFonts.ebGaramond(
                              fontSize: 15,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  /// Show save favorite dialog
  void _showSaveFavoriteDialog(BuildContext context) {
    if (_calendarData.isEmpty) return;
    
    final currentData = _calendarData[_currentPageIndex];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Neyi Favorilere Eklemek İstersin?',
            style: GoogleFonts.ebGaramond(
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.auto_stories, color: Colors.green.shade600),
                title: Text(
                  'Risale-i Nur Metni',
                  style: GoogleFonts.ebGaramond(fontWeight: FontWeight.w600),
                ),
                onTap: () => _saveFavorite(
                  context,
                  'Risale-i Nur',
                  currentData.risaleINur.vecize,
                  currentData.risaleINur.kaynak,
                  currentData.tarih, // Use tarih instead of miladiTarih
                ),
              ),
              ListTile(
                leading: Icon(Icons.book, color: Colors.blue.shade600),
                title: Text(
                  'Ayet/Hadis',
                  style: GoogleFonts.ebGaramond(fontWeight: FontWeight.w600),
                ),
                onTap: () => _saveFavorite(
                  context,
                  'Ayet/Hadis',
                  currentData.ayetHadis.metin,
                  currentData.ayetHadis.kaynak,
                  currentData.tarih, // Use tarih instead of miladiTarih
                ),
              ),
              ListTile(
                leading: Icon(Icons.history, color: Colors.brown.shade600),
                title: Text(
                  'Tarihte Bugün Olayı',
                  style: GoogleFonts.ebGaramond(fontWeight: FontWeight.w600),
                ),
                onTap: () => _saveFavorite(
                  context,
                  'Tarihte Bugün',
                  currentData.tariheBugun,
                  '',
                  currentData.tarih, // Use tarih instead of miladiTarih
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: GoogleFonts.ebGaramond(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Save favorite to database
  Future<void> _saveFavorite(
    BuildContext context,
    String favoriteType,
    String contentText,
    String contentSource,
    String pageDate,
  ) async {
    try {
      await DatabaseHelper.instance.addFavorite(
        favoriteType: favoriteType,
        contentText: contentText,
        contentSource: contentSource,
        pageDate: pageDate,
      );

      // Close dialog
      Navigator.of(context).pop();
      
      // Update favorite state
      setState(() {
        _isCurrentPageFavorited = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favorilere eklendi!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Close dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('zaten favorilerde') 
              ? 'Bu içerik zaten favorilerde mevcut!'
              : 'Favorilere eklenirken hata oluştu!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Check if current page has favorites
  Future<void> _checkPageFavorites() async {
    // Enhanced stability checks
    if (_calendarData.isNotEmpty && 
        _currentPageIndex >= 0 && 
        _currentPageIndex < _calendarData.length &&
        !_isTransitioning &&
        !_isInitialLoad &&
        _hasCompletedFirstRender) {
      
      try {
        final currentData = _calendarData[_currentPageIndex];
        final hasFavorites = await DatabaseHelper.instance.hasPageFavorites(currentData.tarih);
        
        if (mounted) { // Check if widget is still mounted before setState
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

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while data is being loaded OR during initial setup
    if (_isLoading || _isInitialLoad || !_hasCompletedFirstRender || _calendarData.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFF1EAD9), Colors.brown.shade50],
            ),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
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
        ),
      );
    }

    // Additional safety check for data validity
    if (_currentPageIndex < 0 || _currentPageIndex >= _calendarData.length) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFF1EAD9), Colors.brown.shade50],
            ),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Veri yüklenemedi. Lütfen tekrar deneyin.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
            colors: [const Color(0xFFF1EAD9), Colors.brown.shade50],
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
