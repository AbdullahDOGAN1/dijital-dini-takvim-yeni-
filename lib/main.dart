import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/providers/settings_provider.dart';
import 'features/calendar_page/screens/simple_calendar_screen.dart';
import 'features/qibla/screens/qibla_screen.dart';
import 'features/prayer_times/screens/prayer_times_list_screen.dart';
import 'features/dhikr/screens/dhikr_screen.dart';
import './features/favorites/screens/my_favorites_page_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/location/screens/location_settings_screen.dart';
import 'features/daily_content/screens/daily_content_screen.dart';
import 'features/religious_days/screens/religious_days_screen.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create and load settings provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();
  
  runApp(MyApp(settingsProvider: settingsProvider));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  
  const MyApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settingsProvider,
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Nur Vakti',
            themeMode: settings.themeMode,
            theme: AppTheme.getLightThemeData(settings.fontFamily),
            darkTheme: AppTheme.getDarkThemeData(settings.fontFamily),
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/location_settings': (context) => const LocationSettingsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/daily_content': (context) => const DailyContentScreen(),
              '/religious_days': (context) => const ReligiousDaysScreen(),
            },
          );
        },
      ),
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
    const SimpleCalendarScreen(),
    const QiblaScreen(),
    const PrayerTimesListScreen(),
    const MyFavoritesPageScreen(),
  ];

  // Bottom navigation icons
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.explore,
    Icons.access_time,
    Icons.favorite,
  ];

  // Bottom navigation labels
  final List<String> _labels = ['Takvim', 'Kıble', 'Namaz', 'Favoriler'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nur Vakti',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: _buildEndDrawer(),
      body: _screens[_selectedIndex],
      floatingActionButton: Container(
        margin: const EdgeInsets.only(
          top: 10,
        ), // Push down to sit properly in notch
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DhikrScreen()),
            );
          },
          backgroundColor: Colors.green.shade600,
          elevation: 4,
          child: const Icon(Icons.spa, color: Colors.white, size: 24),
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
              Icon(_icons[index], size: 24, color: color),
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
                Icon(Icons.menu_book, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Nur Vakti',
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
            leading: Icon(Icons.auto_stories, color: Colors.deepPurple.shade600),
            title: Text(
              'Bugünün İçeriği',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyContentScreen(),
                ),
              );
            },
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
                MaterialPageRoute(
                  builder: (context) => const MyFavoritesPageScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.star_border, color: Colors.green.shade600),
            title: Text(
              'Dini Günler ve Kandiller',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReligiousDaysScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.location_on_outlined,
              color: Colors.green.shade600,
            ),
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
                MaterialPageRoute(
                  builder: (context) => const LocationSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: Colors.brown.shade600,
            ),
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
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
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
