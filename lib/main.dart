import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'core/theme.dart';
import 'features/calendar_page/screens/calendar_screen.dart';
import 'features/qibla/screens/qibla_screen.dart';
import 'features/prayer_times/screens/prayer_times_list_screen.dart';
import 'features/dhikr/screens/dhikr_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'features/location/screens/location_settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dijital Dini Takvim',
      theme: AppTheme.getThemeData(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // Bottom navigation screens (without dhikr)
  final List<Widget> _screens = [
    const CalendarScreen(),
    const QiblaScreen(),
    const PrayerTimesListScreen(),
    const SettingsScreen(),
  ];

  // Bottom navigation icons
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.explore,
    Icons.access_time,
    Icons.settings,
  ];

  // Bottom navigation labels
  final List<String> _labels = [
    'Takvim',
    'Kıble',
    'Namaz',
    'Ayarlar',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dijital Dini Takvim',
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildEndDrawer(),
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DhikrScreen()),
          );
        },
        backgroundColor: Colors.green.shade600,
        child: const Icon(
          Icons.spa,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _icons.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? Colors.brown.shade700 : Colors.grey.shade500;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icons[index],
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                _labels[index],
                style: GoogleFonts.ebGaramond(
                  fontSize: 12,
                  color: color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        },
        backgroundColor: Colors.white,
        activeIndex: _selectedIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade600, Colors.brown.shade800],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dijital Dini Takvim',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Menü',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.favorite_border, color: Colors.pink.shade600),
            title: Text(
              'Favorilerim',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: Colors.green.shade600),
            title: Text(
              'Konum Ayarları',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationSettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.brown.shade600),
            title: Text(
              'Genel Ayarlar',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue.shade600),
            title: Text(
              'Hakkında',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Dijital Dini Takvim',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.calendar_today,
                  size: 48,
                  color: Colors.brown.shade600,
                ),
                children: [
                  Text(
                    'Günlük dini içerikler, namaz vakitleri ve kıble pusulası ile dini hayatınızı kolaylaştırın.',
                    style: GoogleFonts.ebGaramond(fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
