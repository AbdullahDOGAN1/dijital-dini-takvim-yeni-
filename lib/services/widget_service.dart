import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times_model.dart';
import '../services/daily_content_service.dart';
import '../services/aladhan_api_service.dart';

class WidgetService {
  static const String _groupId = 'group.dijital_dini_takvim.widgets';
  
  // Widget keys
  static const String risaleWidgetKey = 'risale_widget';
  static const String prayerWidgetKey = 'prayer_widget';
  static const String ayetWidgetKey = 'ayet_widget';

  /// Initialize home widget
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_groupId);
      print('🏠 Widget service initialized with group: $_groupId');
    } catch (e) {
      print('❌ Widget initialization error: $e');
    }
  }

  /// Update Risale-i Nur Widget
  static Future<void> updateRisaleWidget() async {
    try {
      final content = await DailyContentService.getTodaysContent();
      
      if (content != null) {
        final data = {
          'title': 'Bugünün Risale-i Nur',
          'content': content.risaleINur.vecize.length > 150 
              ? '${content.risaleINur.vecize.substring(0, 150)}...'
              : content.risaleINur.vecize,
          'source': 'Risale-i Nur',
          'date': DateTime.now().toIso8601String(),
        };
        
        await HomeWidget.saveWidgetData('risale_title', data['title']);
        await HomeWidget.saveWidgetData('risale_content', data['content']);
        await HomeWidget.saveWidgetData('risale_source', data['source']);
        await HomeWidget.saveWidgetData('risale_date', data['date']);
        
        await HomeWidget.updateWidget(
          androidName: 'RisaleWidgetProvider',
          iOSName: 'RisaleWidget',
        );
        
        print('✅ Risale widget updated successfully');
      }
    } catch (e) {
      print('❌ Risale widget update error: $e');
    }
  }

  /// Update Prayer Times Widget
  static Future<void> updatePrayerWidget() async {
    try {
      final apiService = AlAdhanApiService();
      final prayerTimes = await apiService.getPrayerTimes(date: DateTime.now());
      
      if (prayerTimes != null) {
        final nextPrayer = _getNextPrayer(prayerTimes);
        
        final data = {
          'title': 'Bugünün Namaz Vakitleri',
          'imsak': prayerTimes.imsak,
          'gunes': prayerTimes.gunes,
          'ogle': prayerTimes.ogle,
          'ikindi': prayerTimes.ikindi,
          'aksam': prayerTimes.aksam,
          'yatsi': prayerTimes.yatsi,
          'nextPrayer': nextPrayer['name'],
          'nextTime': nextPrayer['time'],
          'location': 'Türkiye',
          'date': DateTime.now().toIso8601String(),
        };
        
        // Save all prayer times
        await HomeWidget.saveWidgetData('prayer_title', data['title']);
        await HomeWidget.saveWidgetData('prayer_imsak', data['imsak']);
        await HomeWidget.saveWidgetData('prayer_gunes', data['gunes']);
        await HomeWidget.saveWidgetData('prayer_ogle', data['ogle']);
        await HomeWidget.saveWidgetData('prayer_ikindi', data['ikindi']);
        await HomeWidget.saveWidgetData('prayer_aksam', data['aksam']);
        await HomeWidget.saveWidgetData('prayer_yatsi', data['yatsi']);
        await HomeWidget.saveWidgetData('prayer_next_name', data['nextPrayer']);
        await HomeWidget.saveWidgetData('prayer_next_time', data['nextTime']);
        await HomeWidget.saveWidgetData('prayer_location', data['location']);
        await HomeWidget.saveWidgetData('prayer_date', data['date']);
        
        await HomeWidget.updateWidget(
          androidName: 'PrayerWidgetProvider',
          iOSName: 'PrayerWidget',
        );
        
        print('✅ Prayer widget updated successfully');
      }
    } catch (e) {
      print('❌ Prayer widget update error: $e');
    }
  }

  /// Update Ayet/Hadis Widget
  static Future<void> updateAyetWidget() async {
    try {
      final content = await DailyContentService.getTodaysContent();
      
      if (content != null) {
        final data = {
          'title': 'Bugünün Ayeti/Hadisi',
          'content': content.ayetHadis.metin.length > 120 
              ? '${content.ayetHadis.metin.substring(0, 120)}...'
              : content.ayetHadis.metin,
          'source': content.ayetHadis.kaynak,
          'type': 'ayet_hadis',
          'date': DateTime.now().toIso8601String(),
        };
        
        await HomeWidget.saveWidgetData('ayet_title', data['title']);
        await HomeWidget.saveWidgetData('ayet_content', data['content']);
        await HomeWidget.saveWidgetData('ayet_source', data['source']);
        await HomeWidget.saveWidgetData('ayet_type', data['type']);
        await HomeWidget.saveWidgetData('ayet_date', data['date']);
        
        await HomeWidget.updateWidget(
          androidName: 'AyetWidgetProvider',
          iOSName: 'AyetWidget',
        );
        
        print('✅ Ayet widget updated successfully');
      }
    } catch (e) {
      print('❌ Ayet widget update error: $e');
    }
  }

  /// Update all widgets
  static Future<void> updateAllWidgets() async {
    print('🔄 Updating all home screen widgets...');
    await Future.wait([
      updateRisaleWidget(),
      updatePrayerWidget(),
      updateAyetWidget(),
    ]);
    print('✅ All widgets updated');
  }

  /// Get next prayer time
  static Map<String, String> _getNextPrayer(PrayerTimesModel prayerTimes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final prayers = [
      {'name': 'İmsak', 'time': prayerTimes.imsak},
      {'name': 'Güneş', 'time': prayerTimes.gunes},
      {'name': 'Öğle', 'time': prayerTimes.ogle},
      {'name': 'İkindi', 'time': prayerTimes.ikindi},
      {'name': 'Akşam', 'time': prayerTimes.aksam},
      {'name': 'Yatsı', 'time': prayerTimes.yatsi},
    ];
    
    for (final prayer in prayers) {
      final timeStr = prayer['time']!;
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final prayerTime = today.add(Duration(hours: hour, minutes: minute));
      
      if (prayerTime.isAfter(now)) {
        return {
          'name': prayer['name']!,
          'time': prayer['time']!,
        };
      }
    }
    
    // If no prayer left today, return tomorrow's Imsak
    return {
      'name': 'İmsak',
      'time': prayerTimes.imsak,
    };
  }

  /// Handle widget tap actions
  static Future<void> handleWidgetTap(String action) async {
    print('🔗 Widget tapped with action: $action');
    // This will be handled by the main app when widget is tapped
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_action', action);
  }

  /// Get pending widget action
  static Future<String?> getPendingWidgetAction() async {
    final prefs = await SharedPreferences.getInstance();
    final action = prefs.getString('widget_action');
    if (action != null) {
      await prefs.remove('widget_action');
    }
    return action;
  }
}
