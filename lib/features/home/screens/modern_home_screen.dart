import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../widgets/home_widgets/next_prayer_countdown_widget.dart';
import '../../../widgets/home_widgets/daily_prayer_times_widget.dart';
import '../../../widgets/home_widgets/hijri_date_widget.dart';
import '../../../widgets/home_widgets/qibla_direction_widget.dart';
import '../../../widgets/home_widgets/daily_verse_widget.dart';
import '../../../widgets/home_widgets/tasbih_counter_widget.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade600,
                      Colors.teal.shade700,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.mosque,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nur Vakti',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _getGreeting(),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: AnimationLimiter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  
                  // Next Prayer Countdown - Priority 1
                  const NextPrayerCountdownWidget(),
                  
                  // Quick Actions Row
                  _buildQuickActionsRow(),
                  
                  // Daily Prayer Times - Priority 2
                  const DailyPrayerTimesWidget(),
                  
                  // Date and Qibla Row
                  _buildDateQiblaRow(),
                  
                  // Daily Content - Priority 3
                  const DailyVerseWidget(),
                  
                  // Tasbih Counter - Priority 4
                  const TasbihCounterWidget(),
                  
                  // Bottom spacing
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return 'Hayırlı geceler';
    } else if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 17) {
      return 'İyi günler';
    } else if (hour < 21) {
      return 'İyi akşamlar';
    } else {
      return 'İyi geceler';
    }
  }

  Widget _buildQuickActionsRow() {
    return AnimationConfiguration.staggeredList(
      position: 1,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.schedule,
                    title: 'Ezan\nVakitleri',
                    color: Colors.blue.shade600,
                    onTap: () {
                      // Navigate to prayer times
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.explore,
                    title: 'Kıble\nYönü',
                    color: Colors.teal.shade600,
                    onTap: () {
                      // Navigate to qibla
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.auto_stories,
                    title: 'Günlük\nİçerik',
                    color: Colors.purple.shade600,
                    onTap: () {
                      // Navigate to daily content
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.spa,
                    title: 'Zikir\nSayacı',
                    color: Colors.brown.shade600,
                    onTap: () {
                      // Navigate to dhikr
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.ebGaramond(
                fontSize: 12,
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

  Widget _buildDateQiblaRow() {
    return AnimationConfiguration.staggeredList(
      position: 3,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        horizontalOffset: -50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: const HijriDateWidget(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: const QiblaDirectionWidget(),
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
