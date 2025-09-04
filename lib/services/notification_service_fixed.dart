import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'aladhan_api_service.dart';

class NotificationServiceFixed {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static AudioPlayer? _currentPlayer;
  
  // Notification channels
  static const String _reminderChannelId = 'prayer_reminders';
  static const String _exactChannelId = 'prayer_exact_times';
  static const String _testChannelId = 'test_notifications';
  
  // Available sounds
  static const List<Map<String, String>> availableSounds = [
    {'key': 'alarm', 'name': '⏰ Alarm Sesi'},
    {'key': 'namaz_vakit_bildirim', 'name': '🔔 Namaz Vakti Bildirimi'},
    {'key': 'fajar_alarm', 'name': '🌅 Fecr Alarmı'},
    {'key': 'athan', 'name': '📢 Ezan (Kısa)'},
    {'key': 'ezan_melodi_1', 'name': '🎵 Ezan Melodi 1'},
  ];

  static const List<Map<String, String>> availableEzanSounds = [
    {'key': 'sabah-ezani-saba-abdulkadir-sehitoglu', 'name': '🌅 Sabah Ezanı'},
    {'key': 'ogle-ezani-rast-abdulkadir-sehitoglu', 'name': '☀️ Öğle Ezanı'},
    {'key': 'ikindi-ezani-hicaz-abdulkadir-sehitoglu', 'name': '🕐 İkindi Ezanı'},
    {'key': 'aksam-ezani-segah-abdulkadir-sehitoglu', 'name': '🌆 Akşam Ezanı'},
    {'key': 'yatsi-ezani-ussak-abdulkadir-sehitoglu', 'name': '🌙 Yatsı Ezanı'},
  ];

  static const List<Map<String, dynamic>> reminderTimeOptions = [
    {'minutes': 1, 'label': '1 dakika önce'},
    {'minutes': 2, 'label': '2 dakika önce'},
    {'minutes': 3, 'label': '3 dakika önce'},
    {'minutes': 5, 'label': '5 dakika önce'},
    {'minutes': 10, 'label': '10 dakika önce'},
    {'minutes': 15, 'label': '15 dakika önce'},
    {'minutes': 30, 'label': '30 dakika önce'},
    {'minutes': 60, 'label': '1 saat önce'},
  ];

  /// Full initialization with permissions
  static Future<bool> initialize() async {
    try {
      print('🚀 Initializing notification service...');
      
      // Initialize timezone
      tz_data.initializeTimeZones();
      print('✅ Timezone initialized');
      
      // Request permissions
      if (Platform.isAndroid) {
        await Permission.notification.request();
        await Permission.scheduleExactAlarm.request();
        print('📱 Android permissions requested');
      }
      
      // Initialize notification plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Create notification channels
      if (Platform.isAndroid) {
        final androidImplementation = 
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // Reminder channel
          await androidImplementation.createNotificationChannel(
            AndroidNotificationChannel(
              _reminderChannelId,
              'Namaz Vakti Hatırlatıcıları',
              description: 'Namaz vaktinden önce gelen hatırlatıcı bildirimleri',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );
          
          // Exact time channel
          await androidImplementation.createNotificationChannel(
            AndroidNotificationChannel(
              _exactChannelId,
              'Namaz Vakti Bildirimleri',
              description: 'Namaz vakti girdiğinde çalan ezan sesleri',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );
          
          // Test channel
          await androidImplementation.createNotificationChannel(
            AndroidNotificationChannel(
              _testChannelId,
              'Test Bildirimleri',
              description: 'Test amaçlı gönderilen bildirimler',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
          
          print('✅ Android notification channels created');
        }
      }
      
      print('✅ Notification service initialized successfully');
      return true;
      
    } catch (e) {
      print('❌ Failed to initialize notification service: $e');
      return false;
    }
  }

  /// Schedule prayer time notifications with enhanced reliability
  static Future<bool> schedulePrayerNotifications() async {
    try {
      print('🔔 ========== PRAYER NOTIFICATION SCHEDULING ==========');
      
      final prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      
      print('🔔 Notifications enabled: $notificationsEnabled');
      
      if (!notificationsEnabled) {
        print('❌ Notifications disabled, skipping schedule');
        return false;
      }

      // Cancel existing notifications
      await _notifications.cancelAll();
      print('🗑️ Cancelled all existing notifications');

      // Get settings
      final reminderMinutes = prefs.getInt('reminder_minutes') ?? 5;
      final notificationSound = prefs.getString('notification_sound') ?? 'alarm';
      final ezanSoundEnabled = prefs.getBool('ezan_sound_enabled') ?? false;
      final ezanSound = prefs.getString('ezan_sound') ?? 'sabah-ezani-saba-abdulkadir-sehitoglu';
      
      print('🔔 Settings loaded:');
      print('   Reminder minutes: $reminderMinutes');
      print('   Notification sound: $notificationSound');
      print('   Ezan sound enabled: $ezanSoundEnabled');
      print('   Ezan sound: $ezanSound');

      // Check permission first
      if (Platform.isAndroid) {
        final hasPermission = await Permission.notification.isGranted;
        final hasSchedulePermission = await Permission.scheduleExactAlarm.isGranted;
        print('🔔 Notification permission: $hasPermission');
        print('🔔 Schedule exact alarm permission: $hasSchedulePermission');
        
        if (!hasPermission) {
          print('❌ Missing notification permission');
          final result = await Permission.notification.request();
          if (result != PermissionStatus.granted) {
            print('❌ Notification permission denied by user');
            return false;
          }
        }
        
        if (!hasSchedulePermission) {
          print('❌ Missing schedule exact alarm permission');
          final result = await Permission.scheduleExactAlarm.request();
          if (result != PermissionStatus.granted) {
            print('⚠️ Schedule exact alarm permission denied - notifications may be delayed');
          }
        }
      }

      // Schedule for multiple days (today + next 2 days for reliability)
      final today = DateTime.now();
      int totalScheduled = 0;
      
      // Initialize AlAdhan API service
      final alAdhanService = AlAdhanApiService();

      for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
        final targetDate = today.add(Duration(days: dayOffset));
        final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        
        print('🔔 =========== SCHEDULING FOR $dateStr ===========');

        // Get location settings
        final prefs = await SharedPreferences.getInstance();
        double? latitude;
        double? longitude;
        
        final bool usingCurrentLocation = prefs.getBool('using_current_location') ?? true;
        
        if (!usingCurrentLocation) {
          // User selected a specific city
          final selectedCity = prefs.getString('selected_city');
          if (selectedCity != null) {
            // Use saved coordinates for selected city
            latitude = prefs.getDouble('selected_latitude');
            longitude = prefs.getDouble('selected_longitude');
          }
        } else {
          // Use current GPS location
          latitude = prefs.getDouble('current_latitude');
          longitude = prefs.getDouble('current_longitude');
        }
        
        // Default to Istanbul if no coordinates
        latitude ??= 41.0082;
        longitude ??= 28.9784;

        // Get prayer times from AlAdhan API (same as main app)
        final prayerTimes = await alAdhanService.getPrayerTimes(
          date: targetDate,
          latitude: latitude,
          longitude: longitude,
        );
        
        if (prayerTimes == null) {
          print('❌ Could not fetch prayer times for $dateStr');
          continue;
        }
        
        final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
        
        print('🔔 Prayer times for $dateStr:');
        print('   İmsak: ${prayerTimes.imsak}');
        print('   Güneş: ${prayerTimes.gunes}');
        print('   Öğle: ${prayerTimes.ogle}');
        print('   İkindi: ${prayerTimes.ikindi}');
        print('   Akşam: ${prayerTimes.aksam}');
        print('   Yatsı: ${prayerTimes.yatsi}');

        // Prayer time mapping (only main prayer times for reminders)
        final prayers = [
          {'name': 'İmsak', 'time': prayerTimes.imsak, 'isMain': false},
          {'name': 'Öğle', 'time': prayerTimes.ogle, 'isMain': true},
          {'name': 'İkindi', 'time': prayerTimes.ikindi, 'isMain': true},
          {'name': 'Akşam', 'time': prayerTimes.aksam, 'isMain': true},
          {'name': 'Yatsı', 'time': prayerTimes.yatsi, 'isMain': true},
        ];

        int notificationId = (dayOffset * 100) + 1; // Unique IDs per day
        
        for (final prayer in prayers) {
          final prayerName = prayer['name'] as String;
          final prayerTimeStr = prayer['time'] as String;
          final isMainPrayer = prayer['isMain'] as bool;
          
          print('🔔 ==========================================');
          print('🔔 Processing: $prayerName at $prayerTimeStr (Main: $isMainPrayer)');
          
          // Parse prayer time
          final prayerDateTime = _parsePrayerTime(targetDay, prayerTimeStr);
          if (prayerDateTime == null) {
            print('❌ Could not parse time: $prayerTimeStr');
            continue;
          }
          
          print('🔔 Prayer datetime: ${prayerDateTime.toString()}');
          print('🔔 Is after now: ${prayerDateTime.isAfter(today)}');
          
          // Only schedule for future times
          if (prayerDateTime.isAfter(today)) {
            // Schedule reminder notification (only for main prayers)
            if (isMainPrayer) {
              final reminderTime = prayerDateTime.subtract(Duration(minutes: reminderMinutes));
              print('🔔 Reminder time: ${reminderTime.toString()}');
              print('🔔 Reminder is after now: ${reminderTime.isAfter(today)}');
              
              if (reminderTime.isAfter(today)) {
                final success = await _scheduleNotification(
                  id: notificationId++,
                  title: '$prayerName Vakti Yaklaşıyor',
                  body: '$reminderMinutes dakika sonra $prayerName vakti ($prayerTimeStr)',
                  scheduledTime: reminderTime,
                  payload: '$prayerName|$prayerTimeStr|reminder|$dateStr',
                  channelId: _reminderChannelId,
                  playCustomSound: false,
                  soundName: notificationSound,
                );
                
                if (success) {
                  totalScheduled++;
                  print('✅ Scheduled reminder for $prayerName on $dateStr');
                }
              } else {
                print('⚠️ Reminder time has passed for $prayerName on $dateStr');
              }
            }
            
            // Schedule exact time notification (if ezan sound enabled and main prayer)
            if (ezanSoundEnabled && isMainPrayer) {
              final success = await _scheduleNotification(
                id: notificationId++,
                title: '$prayerName Vakti',
                body: '$prayerName vakti girdi ($prayerTimeStr)',
                scheduledTime: prayerDateTime,
                payload: '$prayerName|$prayerTimeStr|exact_time|$dateStr',
                channelId: _exactChannelId,
                playCustomSound: true,
                soundName: ezanSound,
              );
              
              if (success) {
                totalScheduled++;
                print('✅ Scheduled exact time for $prayerName on $dateStr');
              }
            }
          } else {
            print('⚠️ Prayer time has passed: $prayerName on $dateStr');
          }
        }
      }

      print('🔔 ==========================================');
      print('🔔 SCHEDULING SUMMARY:');
      print('🔔 Total notifications scheduled: $totalScheduled');
      
      // Save scheduling timestamp
      await prefs.setInt('last_notification_schedule', DateTime.now().millisecondsSinceEpoch);
      
      // Verify scheduled notifications
      await showPendingNotifications();
      
      return totalScheduled > 0;
      
    } catch (e, stackTrace) {
      print('❌ Error in schedulePrayerNotifications: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Enhanced prayer time parsing
  static DateTime? _parsePrayerTime(DateTime today, String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      if (timeParts.length < 2) return null;
      
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;
      
      return DateTime(today.year, today.month, today.day, hour, minute);
    } catch (e) {
      print('❌ Error parsing prayer time "$timeStr": $e');
      return null;
    }
  }
  
  /// Core notification scheduling function
  static Future<bool> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String channelId,
    bool playCustomSound = false,
    String? soundName,
  }) async {
    try {
      // Initialize timezone data first
      tz_data.initializeTimeZones();
      
      // Set Turkey timezone explicitly
      final turkeyLocation = tz.getLocation('Europe/Istanbul');
      
      // Get current time in Turkey timezone
      final now = tz.TZDateTime.now(turkeyLocation);
      
      print('🔔 SCHEDULING NOTIFICATION:');
      print('🔔 ID: $id');
      print('🔔 Title: $title');
      print('🔔 Original scheduled time: ${scheduledTime.toString()}');
      print('🔔 Current time (Turkey): ${now.toString()}');
      print('🔔 Channel: $channelId');
      print('🔔 Custom sound: $playCustomSound');
      print('🔔 Sound name: $soundName');
      print('🔔 Turkey timezone: ${turkeyLocation.name}');
      
      // Convert scheduled time to Turkey timezone properly
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime(
        turkeyLocation, 
        scheduledTime.year, 
        scheduledTime.month, 
        scheduledTime.day, 
        scheduledTime.hour, 
        scheduledTime.minute,
        scheduledTime.second,
      );
      
      print('🔔 TZ Scheduled time (Turkey): ${tzScheduledTime.toString()}');
      print('🔔 TZ UTC offset: ${tzScheduledTime.timeZoneOffset}');
      print('🔔 Is after now: ${tzScheduledTime.isAfter(now)}');
      
      // Validate scheduling time
      if (!tzScheduledTime.isAfter(now)) {
        print('❌ Cannot schedule notification in the past');
        print('❌ Scheduled: ${tzScheduledTime.toString()}');
        print('❌ Current: ${now.toString()}');
        return false;
      }
      
      // Notification details with enhanced sound support
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _reminderChannelId ? 'Namaz Vakti Hatırlatıcıları' : 'Namaz Vakti Bildirimleri',
        channelDescription: channelId == _reminderChannelId 
            ? 'Namaz vaktinden önce gelen hatırlatıcı bildirimleri'
            : 'Namaz vakti girdiğinde çalan ezan sesleri',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        playSound: false, // Disable sounds for now
        autoCancel: true,
        category: channelId == _reminderChannelId 
            ? AndroidNotificationCategory.reminder 
            : AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
        ticker: title,
        // Enhanced sound configuration  
        sound: null, // Disable custom sounds for now
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        fullScreenIntent: channelId == _exactChannelId, // Full screen for ezan times
        actions: channelId == _exactChannelId ? [
          const AndroidNotificationAction(
            'stop_sound',
            'Sesi Durdur',
            icon: DrawableResourceAndroidBitmap('ic_stop'),
          ),
        ] : null,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Schedule the notification
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      // Verify scheduling
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      final isScheduled = pendingNotifications.any((n) => n.id == id);
      
      if (isScheduled) {
        print('✅ Notification scheduled successfully');
        print('✅ Will fire at: ${tzScheduledTime.toString()}');
        return true;
      } else {
        print('❌ Notification scheduling verification failed');
        return false;
      }
      
    } catch (e, stackTrace) {
      print('❌ Error scheduling notification: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /// Test immediate notification (5 seconds)
  static Future<void> testImmediateNotification() async {
    final testTime = DateTime.now().add(Duration(seconds: 5));
    
    await _scheduleNotification(
      id: 999,
      title: 'Test Bildirimi',
      body: 'Bu bir test bildirimidir - 5 saniye sonra geldi!',
      scheduledTime: testTime,
      payload: 'test|immediate|test',
      channelId: _testChannelId,
    );
    
    print('🧪 Test notification scheduled for 5 seconds from now');
  }
  
  /// Send instant test notification
  static Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _testChannelId,
      'Test Bildirimleri',
      channelDescription: 'Test amaçlı gönderilen bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _notifications.show(
      998,
      'Test Bildirimi',
      'Bildirim sistemi çalışıyor! ✅',
      notificationDetails,
      payload: 'test|instant|test',
    );
    
    print('🧪 Instant test notification sent');
  }
  
  /// Test notification at specific time
  static Future<void> testSpecificTimeNotification(DateTime targetTime) async {
    print('🧪 ========== SPECIFIC TIME TEST ==========');
    print('🧪 Target time: ${targetTime.toString()}');
    print('🧪 Current time: ${DateTime.now().toString()}');
    
    final success = await _scheduleNotification(
      id: 999,
      title: 'Test Bildirimi',
      body: 'Bu ${targetTime.hour}:${targetTime.minute.toString().padLeft(2, '0')} için zamanlanmış test bildirimidir.',
      scheduledTime: targetTime,
      payload: 'test|specific|${targetTime.millisecondsSinceEpoch}',
      channelId: _testChannelId,
    );
    
    if (success) {
      print('✅ Test notification scheduled successfully');
    } else {
      print('❌ Test notification scheduling failed');
    }
  }

  /// Show all pending notifications for debugging
  static Future<void> showPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 ==========================================');
      print('📋 PENDING NOTIFICATIONS (${pending.length}):');
      
      for (int i = 0; i < pending.length; i++) {
        final notification = pending[i];
        print('📋 ${i + 1}. ID: ${notification.id}');
        print('📋    Title: ${notification.title}');
        print('📋    Body: ${notification.body}');
        print('📋    Payload: ${notification.payload}');
      }
      
      if (pending.isEmpty) {
        print('📋 No pending notifications found');
      }
      
    } catch (e) {
      print('❌ Failed to verify scheduled notifications: $e');
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) async {
    print('📱 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      final parts = response.payload!.split('|');
      if (parts.length >= 3) {
        final prayerName = parts[0];
        final prayerTime = parts[1];
        final type = parts[2];
        
        print('📱 Prayer: $prayerName, Time: $prayerTime, Type: $type');
        
        // If this is an exact prayer time notification, play ezan automatically
        if (type == 'exact_time') {
          final prefs = await SharedPreferences.getInstance();
          final ezanEnabled = prefs.getBool('ezan_sound_enabled') ?? false;
          
          if (ezanEnabled) {
            final ezanSound = prefs.getString('ezan_sound') ?? 'sabah-ezani-saba-abdulkadir-sehitoglu';
            print('🕌 Auto-playing ezan for $prayerName');
            await playEzanSound(ezanSound);
            
            // Auto-stop ezan after 3 minutes
            Future.delayed(Duration(minutes: 3), () async {
              if (_currentPlayer != null) {
                print('🔔 Auto-stopping ezan after 3 minutes');
                await stopCurrentSound();
              }
            });
          }
        }
      }
    }
  }
  
  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }
  
  /// Settings management
  static Future<Map<String, dynamic>> getCurrentSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'notifications_enabled': prefs.getBool('notifications_enabled') ?? false,
        'reminder_minutes': prefs.getInt('reminder_minutes') ?? 5,
        'notification_sound': prefs.getString('notification_sound') ?? 'alarm',
        'ezan_sound_enabled': prefs.getBool('ezan_sound_enabled') ?? false,
        'ezan_sound': prefs.getString('ezan_sound') ?? 'sabah-ezani-saba-abdulkadir-sehitoglu',
      };
    } catch (e) {
      print('❌ Error getting current settings: $e');
      return {};
    }
  }
  
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (enabled) {
      await schedulePrayerNotifications();
    } else {
      await cancelAllNotifications();
    }
    
    print('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
  }
  
  static Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
    print('⏰ Reminder minutes set to: $minutes');
  }
  
  static Future<void> setNotificationSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', sound);
    print('🔊 Notification sound set to: $sound');
  }
  
  static Future<void> setEzanSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ezan_sound_enabled', enabled);
    print('🕌 Ezan sound ${enabled ? 'enabled' : 'disabled'}');
  }
  
  static Future<void> setEzanSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ezan_sound', sound);
    print('🕌 Ezan sound set to: $sound');
  }

  /// Sound management
  static Future<void> stopCurrentSound() async {
    try {
      if (_currentPlayer != null) {
        await _currentPlayer!.stop();
        await _currentPlayer!.dispose();
        _currentPlayer = null;
        print('✅ Sound stopped successfully');
      }
    } catch (e) {
      print('❌ Error stopping current player: $e');
    }
  }
  
  static Future<void> _stopCurrentPlayer() async {
    await stopCurrentSound();
  }
  
  static Future<void> playNotificationSound(String soundName) async {
    await _stopCurrentPlayer();
    
    try {
      print('🔊 Playing notification sound: $soundName');
      
      _currentPlayer = AudioPlayer();
      
      // Check if this is a custom sound
      if (soundName.startsWith('custom_')) {
        // Custom sound - use DeviceFileSource
        final appDir = await getApplicationDocumentsDirectory();
        final soundPath = '${appDir.path}/sounds/$soundName.mp3';
        final soundPathWav = '${appDir.path}/sounds/$soundName.wav';
        
        // Try .mp3 first, then .wav
        if (File(soundPath).existsSync()) {
          await _currentPlayer!.play(DeviceFileSource(soundPath));
          print('✅ Playing custom notification sound from: $soundPath');
        } else if (File(soundPathWav).existsSync()) {
          await _currentPlayer!.play(DeviceFileSource(soundPathWav));
          print('✅ Playing custom notification sound from: $soundPathWav');
        } else {
          print('❌ Custom notification sound file not found: $soundPath or $soundPathWav');
          return;
        }
      } else {
        // Asset sound
        await _currentPlayer!.play(AssetSource('sounds/$soundName.mp3'));
        print('✅ Playing asset notification sound: sounds/$soundName.mp3');
      }
      
      // Auto-stop after 5 seconds for notification sounds (preview)
      Future.delayed(Duration(seconds: 5), () async {
        if (_currentPlayer != null) {
          print('🔊 Auto-stopping notification sound preview after 5 seconds');
          await stopCurrentSound();
        }
      });
      
      print('✅ Notification sound played successfully');
    } catch (e) {
      print('❌ Error playing notification sound: $e');
    }
  }
  
  static Future<void> playEzanSound(String soundName) async {
    await _stopCurrentPlayer();
    
    try {
      print('🕌 Playing ezan sound: $soundName');
      
      _currentPlayer = AudioPlayer();
      
      // Check if this is a custom sound
      if (soundName.startsWith('custom_')) {
        // Custom sound - use DeviceFileSource
        final appDir = await getApplicationDocumentsDirectory();
        final soundPath = '${appDir.path}/sounds/$soundName.mp3';
        final soundPathWav = '${appDir.path}/sounds/$soundName.wav';
        
        // Try .mp3 first, then .wav
        if (File(soundPath).existsSync()) {
          await _currentPlayer!.play(DeviceFileSource(soundPath));
          print('✅ Playing custom ezan sound from: $soundPath');
        } else if (File(soundPathWav).existsSync()) {
          await _currentPlayer!.play(DeviceFileSource(soundPathWav));
          print('✅ Playing custom ezan sound from: $soundPathWav');
        } else {
          print('❌ Custom ezan sound file not found: $soundPath or $soundPathWav');
          return;
        }
      } else {
        // Asset sound
        await _currentPlayer!.play(AssetSource('sounds/$soundName.mp3'));
        print('✅ Playing asset ezan sound: sounds/$soundName.mp3');
      }
      
      // Auto-stop after 10 seconds for ezan sounds (preview)
      Future.delayed(Duration(seconds: 10), () async {
        if (_currentPlayer != null) {
          print('🔔 Auto-stopping ezan sound preview after 10 seconds');
          await stopCurrentSound();
        }
      });
      
      print('✅ Ezan sound played successfully');
    } catch (e) {
      print('❌ Error playing ezan sound: $e');
    }
  }
  
  /// Get all sounds
  static Future<List<Map<String, String>>> getAllNotificationSounds() async {
    List<Map<String, String>> sounds = List.from(availableSounds);
    
    // Add custom sounds
    try {
      final prefs = await SharedPreferences.getInstance();
      final customSounds = prefs.getStringList('custom_sounds') ?? [];
      
      for (String customSound in customSounds) {
        final parts = customSound.split('|');
        if (parts.length >= 3 && parts[2] == 'notification') {
          final fileName = parts[0];
          final displayName = parts[1];
          sounds.add({
            'key': fileName.replaceAll('.mp3', '').replaceAll('.wav', ''),
            'name': '🎵 $displayName',
          });
        }
      }
    } catch (e) {
      print('❌ Error loading custom notification sounds: $e');
    }
    
    return sounds;
  }
  
  static Future<List<Map<String, String>>> getAllEzanSounds() async {
    List<Map<String, String>> sounds = List.from(availableEzanSounds);
    
    // Add custom sounds
    try {
      final prefs = await SharedPreferences.getInstance();
      final customSounds = prefs.getStringList('custom_sounds') ?? [];
      
      for (String customSound in customSounds) {
        final parts = customSound.split('|');
        if (parts.length >= 3 && parts[2] == 'ezan') {
          final fileName = parts[0];
          final displayName = parts[1];
          sounds.add({
            'key': fileName.replaceAll('.mp3', '').replaceAll('.wav', ''),
            'name': '🕌 $displayName',
          });
        }
      }
    } catch (e) {
      print('❌ Error loading custom ezan sounds: $e');
    }
    
    return sounds;
  }
}
