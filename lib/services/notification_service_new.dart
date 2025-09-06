import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:path_provider/path_provider.dart';
import 'prayer_api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  // Use a single AudioPlayer instance and manage it better
  static AudioPlayer? _currentPlayer;
  
  // Notification channel IDs for Android
  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'Namaz Vakti Hatırlatıcıları';
  static const String _channelDescription = 'Namaz vakitleri için hatırlatıcı bildirimleri';

  // Available sounds
  static const List<Map<String, String>> availableSounds = [
    {'key': 'bell_soft', 'name': 'Yumuşak Zil'},
    {'key': 'bell_modern', 'name': 'Modern Zil'},
    {'key': 'chime_peaceful', 'name': 'Huzurlu Çan'},
    {'key': 'chime_crystal', 'name': 'Kristal Çan'},
    {'key': 'notification_gentle', 'name': 'Nazik Bildirim'},
    {'key': 'notification_elegant', 'name': 'Zarif Bildirim'},
    {'key': 'dhikr_reminder', 'name': 'Zikir Hatırlatıcısı'},
  ];

  static const List<Map<String, String>> availableEzanSounds = [
    {'key': 'azan_traditional', 'name': 'Geleneksel Ezan'},
    {'key': 'azan_beautiful', 'name': 'Güzel Ezan'},
    {'key': 'quran_recitation', 'name': 'Kuran Tilaveti'},
  ];

  // Reminder time options in minutes
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

  /// Get all available notification sounds including custom ones
  static Future<List<Map<String, String>>> getAllNotificationSounds() async {
    final List<Map<String, String>> allSounds = List.from(availableSounds);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> customSounds = prefs.getStringList('custom_sounds') ?? [];
      
      for (String customSound in customSounds) {
        final parts = customSound.split('|');
        if (parts.length >= 3 && parts[2] == 'notification') {
          allSounds.add({
            'key': parts[0].replaceAll('.mp3', '').replaceAll('.wav', ''),
            'name': '${parts[1]} (Özel)',
          });
        }
      }
    } catch (e) {
      print('❌ Error loading custom notification sounds: $e');
    }
    
    return allSounds;
  }

  /// Get all available ezan sounds including custom ones
  static Future<List<Map<String, String>>> getAllEzanSounds() async {
    final List<Map<String, String>> allSounds = List.from(availableEzanSounds);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> customSounds = prefs.getStringList('custom_sounds') ?? [];
      
      for (String customSound in customSounds) {
        final parts = customSound.split('|');
        if (parts.length >= 3 && parts[2] == 'ezan') {
          allSounds.add({
            'key': parts[0].replaceAll('.mp3', '').replaceAll('.wav', ''),
            'name': '${parts[1]} (Özel)',
          });
        }
      }
    } catch (e) {
      print('❌ Error loading custom ezan sounds: $e');
    }
    
    return allSounds;
  }

  /// Check if a sound is custom (user-added)
  static Future<bool> isCustomSound(String soundKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> customSounds = prefs.getStringList('custom_sounds') ?? [];
      
      return customSounds.any((sound) => sound.startsWith(soundKey));
    } catch (e) {
      print('❌ Error checking if sound is custom: $e');
      return false;
    }
  }

  /// Initialize notification service
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    await _createNotificationChannel();
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    
    // Parse payload to get prayer info
    if (response.payload != null) {
      final parts = response.payload!.split('|');
      if (parts.length >= 2) {
        final prayerName = parts[0];
        final prayerTime = parts[1];
        print('Prayer: $prayerName at $prayerTime');
        
        // Play ezan sound if it's prayer time notification (not reminder)
        if (response.payload!.contains('exact_time')) {
          _playEzanSoundIfEnabled();
        }
      }
    }
  }

  /// Schedule prayer time notifications for today
  static Future<void> schedulePrayerNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      
      if (!notificationsEnabled) {
        print('Notifications disabled, skipping schedule');
        return;
      }

      // Cancel existing notifications
      await cancelAllNotifications();

      // Get settings
      final reminderMinutes = prefs.getInt('reminder_minutes') ?? 5;
      final notificationSound = prefs.getString('notification_sound') ?? 'bell_soft';

      // Get today's prayer times
      final prayerTimes = await PrayerApiService.getPrayerTimesForToday();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Prayer time names and times
      final Map<String, String> prayers = {
        'İmsak': prayerTimes.imsak,
        'Güneş': prayerTimes.gunes,
        'Öğle': prayerTimes.ogle,
        'İkindi': prayerTimes.ikindi,
        'Akşam': prayerTimes.aksam,
        'Yatsı': prayerTimes.yatsi,
      };

      int notificationId = 1;

      for (final entry in prayers.entries) {
        final prayerName = entry.key;
        final prayerTimeStr = entry.value;
        
        if (prayerTimeStr.isNotEmpty) {
          try {
            final prayerTime = _parseTimeString(prayerTimeStr, today);
            
            // Only schedule if prayer time is in the future
            if (prayerTime.isAfter(now)) {
              // Schedule reminder notification
              final reminderTime = prayerTime.subtract(Duration(minutes: reminderMinutes));
              if (reminderTime.isAfter(now)) {
                await _scheduleNotification(
                  id: notificationId++,
                  title: '$prayerName Vakti Yaklaştı',
                  body: '$reminderMinutes dakika sonra $prayerName vakti ($prayerTimeStr)',
                  scheduledTime: reminderTime,
                  payload: '$prayerName|$prayerTimeStr|reminder',
                );
              }

              // Schedule exact time notification
              await _scheduleNotification(
                id: notificationId++,
                title: '$prayerName Vakti',
                body: '$prayerName vakti geldi ($prayerTimeStr)',
                scheduledTime: prayerTime,
                payload: '$prayerName|$prayerTimeStr|exact_time',
              );
            }
          } catch (e) {
            print('Error parsing time for $prayerName: $e');
          }
        }
      }

      print('✅ Scheduled ${notificationId - 1} prayer notifications');
    } catch (e) {
      print('❌ Error scheduling prayer notifications: $e');
    }
  }

  /// Parse time string (HH:mm) to DateTime
  static DateTime _parseTimeString(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    if (parts.length != 2) throw FormatException('Invalid time format: $timeStr');
    
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  /// Schedule a single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      final tz.TZDateTime tzScheduledTime = _convertToTZDateTime(scheduledTime);
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
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
      
      print('✅ Scheduled notification: $title at ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Convert DateTime to TZDateTime
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('Cancelled all notifications');
  }

  /// Improved sound playing with better error handling and platform-specific fixes
  static Future<void> playNotificationSound(String soundName) async {
    await _stopCurrentPlayer();
    
    try {
      _currentPlayer = AudioPlayer();
      
      // Configure player mode for better Android compatibility
      await _currentPlayer!.setPlayerMode(PlayerMode.lowLatency);
      
      bool played = false;
      
      // Check if it's a custom sound
      final isCustom = await isCustomSound(soundName);
      
      if (isCustom) {
        // Play custom sound from documents directory
        try {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String soundPath = '${appDir.path}/sounds/$soundName.mp3';
          final File soundFile = File(soundPath);
          
          if (await soundFile.exists()) {
            await _currentPlayer!.play(DeviceFileSource(soundPath));
            played = true;
            print('✅ Custom notification sound played: $soundName');
          } else {
            print('❌ Custom sound file not found: $soundPath');
          }
        } catch (e) {
          print('❌ Custom sound playback failed: $e');
        }
      }
      
      if (!played) {
        // Method 1: Standard AssetSource (most compatible)
        try {
          final source = AssetSource('sounds/$soundName.mp3');
          await _currentPlayer!.play(source);
          played = true;
          print('✅ Notification sound played successfully: $soundName');
        } catch (e) {
          print('❌ AssetSource method failed: $e');
          
          // Method 2: Try with setSource and resume separately
          try {
            await _currentPlayer!.setSource(AssetSource('sounds/$soundName.mp3'));
            await _currentPlayer!.resume();
            played = true;
            print('✅ Notification sound played with setSource+resume: $soundName');
          } catch (e2) {
            print('❌ SetSource+resume method failed: $e2');
            
            // Method 3: Platform channel fallback (for stubborn Android issues)
            try {
              await _playSystemNotificationSound();
              played = true;
              print('✅ System notification sound played as fallback');
            } catch (e3) {
              print('❌ System sound fallback failed: $e3');
            }
          }
        }
      }
      
      if (!played) {
        print('❌ All audio methods failed, using haptic feedback');
        try {
          HapticFeedback.mediumImpact();
          await Future.delayed(Duration(milliseconds: 100));
          HapticFeedback.mediumImpact();
          print('🔊 Haptic feedback pattern triggered');
        } catch (e) {
          print('❌ Haptic feedback also failed: $e');
        }
      } else {
        // Configure successful playback
        await _currentPlayer!.setVolume(0.9);
        
        // Auto-stop after 4 seconds
        Future.delayed(Duration(seconds: 4), () async {
          await _stopCurrentPlayer();
        });
      }
      
    } catch (e) {
      print('❌ Critical error in playNotificationSound: $e');
      await _stopCurrentPlayer();
    }
  }

  /// Play system notification sound as fallback
  static Future<void> _playSystemNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(Duration(milliseconds: 200));
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('❌ System sound failed: $e');
      rethrow;
    }
  }

  /// Play ezan sound if enabled
  static Future<void> _playEzanSoundIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool ezanEnabled = prefs.getBool('ezan_sound_enabled') ?? false;
      
      if (ezanEnabled) {
        final String ezanSound = prefs.getString('ezan_sound') ?? 'azan_traditional';
        await playEzanSound(ezanSound);
      }
    } catch (e) {
      print('❌ Error playing ezan sound: $e');
    }
  }

  /// Play ezan sound with improved error handling and platform compatibility
  static Future<void> playEzanSound(String soundName) async {
    await _stopCurrentPlayer();
    
    try {
      _currentPlayer = AudioPlayer();
      
      // Configure for better Android compatibility
      await _currentPlayer!.setPlayerMode(PlayerMode.lowLatency);
      
      bool played = false;
      
      // Check if it's a custom sound
      final isCustom = await isCustomSound(soundName);
      
      if (isCustom) {
        // Play custom ezan sound from documents directory
        try {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String soundPath = '${appDir.path}/sounds/$soundName.mp3';
          final File soundFile = File(soundPath);
          
          if (await soundFile.exists()) {
            await _currentPlayer!.play(DeviceFileSource(soundPath));
            played = true;
            print('✅ Custom ezan sound played: $soundName');
          } else {
            print('❌ Custom ezan sound file not found: $soundPath');
          }
        } catch (e) {
          print('❌ Custom ezan sound playback failed: $e');
        }
      }
      
      if (!played) {
        // Method 1: Standard AssetSource
        try {
          final source = AssetSource('sounds/$soundName.mp3');
          await _currentPlayer!.play(source);
          played = true;
          print('✅ Ezan sound played successfully: $soundName');
        } catch (e) {
          print('❌ Ezan AssetSource failed: $e');
          
          // Method 2: SetSource + Resume
          try {
            await _currentPlayer!.setSource(AssetSource('sounds/$soundName.mp3'));
            await _currentPlayer!.resume();
            played = true;
            print('✅ Ezan sound played with setSource+resume: $soundName');
          } catch (e2) {
            print('❌ Ezan setSource+resume failed: $e2');
            
            // Method 3: Enhanced haptic pattern for ezan
            try {
              await _playEzanHapticPattern();
              played = true;
              print('✅ Ezan haptic pattern played as fallback');
            } catch (e3) {
              print('❌ Ezan haptic pattern failed: $e3');
            }
          }
        }
      }
      
      if (played && _currentPlayer != null) {
        await _currentPlayer!.setVolume(1.0); // Full volume for ezan
        
        // Auto-stop after 15 seconds for ezan (longer duration)
        Future.delayed(Duration(seconds: 15), () async {
          await _stopCurrentPlayer();
        });
      }
      
    } catch (e) {
      print('❌ Critical error in playEzanSound: $e');
      await _stopCurrentPlayer();
    }
  }

  /// Enhanced haptic feedback pattern for ezan
  static Future<void> _playEzanHapticPattern() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(Duration(milliseconds: 300));
      await HapticFeedback.mediumImpact();
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  /// Stop current player safely
  static Future<void> _stopCurrentPlayer() async {
    try {
      if (_currentPlayer != null) {
        await _currentPlayer!.stop();
        await _currentPlayer!.dispose();
        _currentPlayer = null;
      }
    } catch (e) {
      print('❌ Error stopping player: $e');
      _currentPlayer = null;
    }
  }

  /// Send test notification with improved feedback
  static Future<void> sendTestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationSound = prefs.getString('notification_sound') ?? 'bell_soft';

      await _notifications.show(
        999,
        'Test Bildirimi 🔔',
        'Bu bir test bildirimidir. Bildirimler düzgün çalışıyor!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: 'test|notification|test',
      );

      // Play notification sound
      await playNotificationSound(notificationSound);
      
      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Test ezan sound
  static Future<void> testEzanSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ezanSound = prefs.getString('ezan_sound') ?? 'azan_traditional';
      
      await playEzanSound(ezanSound);
      print('✅ Test ezan sound played');
    } catch (e) {
      print('❌ Error testing ezan sound: $e');
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  /// Enable/disable notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (enabled) {
      await schedulePrayerNotifications();
    } else {
      await cancelAllNotifications();
    }
  }

  /// Set reminder time in minutes
  static Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
    
    // Reschedule if notifications are enabled
    final bool enabled = prefs.getBool('notifications_enabled') ?? false;
    if (enabled) {
      await schedulePrayerNotifications();
    }
  }

  /// Set reminder minutes
  static Future<void> setReminderTime(int minutes) async {
    await setReminderMinutes(minutes);
  }

  /// Set notification sound
  static Future<void> setNotificationSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', sound);
  }

  /// Set ezan sound enabled
  static Future<void> setEzanSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ezan_sound_enabled', enabled);
  }

  /// Set ezan sound
  static Future<void> setEzanSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ezan_sound', sound);
  }
}
