import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer_times_model.dart';
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

  /// Initialize notification service
  static Future<void> initialize() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
      
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
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
      final prayers = {
        'İmsak': prayerTimes.imsak,
        'Güneş': prayerTimes.gunes,
        'Öğle': prayerTimes.ogle,
        'İkindi': prayerTimes.ikindi,
        'Akşam': prayerTimes.aksam,
        'Yatsı': prayerTimes.yatsi,
      };

      int notificationId = 1000;

      for (final entry in prayers.entries) {
        final prayerName = entry.key;
        final timeString = entry.value;
        
        // Parse time string (HH:mm format)
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          
          final prayerTime = DateTime(today.year, today.month, today.day, hour, minute);
          final reminderTime = prayerTime.subtract(Duration(minutes: reminderMinutes));
          
          // Schedule reminder notification
          if (reminderTime.isAfter(now)) {
            await _scheduleNotification(
              id: notificationId++,
              title: '$prayerName Vakti Yaklaşıyor',
              body: '$prayerName vakti $reminderMinutes dakika sonra ($timeString)',
              scheduledTime: reminderTime,
              sound: notificationSound,
              payload: '$prayerName|$timeString|reminder',
            );
            
            print('Scheduled reminder for $prayerName at ${reminderTime.toString()}');
          }

          // Schedule exact prayer time notification
          if (prayerTime.isAfter(now)) {
            await _scheduleNotification(
              id: notificationId++,
              title: '$prayerName Vakti Girdi',
              body: '$prayerName vakti girmiştir. ($timeString)',
              scheduledTime: prayerTime,
              sound: notificationSound,
              payload: '$prayerName|$timeString|exact_time',
            );
            
            print('Scheduled exact time notification for $prayerName at ${prayerTime.toString()}');
          }
        }
      }

      print('Prayer notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling prayer notifications: $e');
    }
  }

  /// Schedule a single notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String sound,
    String? payload,
  }) async {
    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF00695C), // Teal color
    );

    // iOS notification details  
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
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

  /// Improved sound playing with better error handling
  static Future<void> playNotificationSound(String soundName) async {
    await _stopCurrentPlayer();
    
    try {
      _currentPlayer = AudioPlayer();
      
      // Try multiple methods to play the sound
      bool played = false;
      
      // Method 1: Direct asset play
      try {
        await _currentPlayer!.play(AssetSource('sounds/$soundName.mp3'));
        played = true;
        print('✅ Notification sound played successfully (method 1): $soundName');
      } catch (e) {
        print('❌ Method 1 failed: $e');
      }
      
      // Method 2: Set source then resume
      if (!played) {
        try {
          await _currentPlayer!.setSource(AssetSource('sounds/$soundName.mp3'));
          await _currentPlayer!.resume();
          played = true;
          print('✅ Notification sound played successfully (method 2): $soundName');
        } catch (e) {
          print('❌ Method 2 failed: $e');
        }
      }
      
      // Method 3: URL source with asset prefix
      if (!played) {
        try {
          await _currentPlayer!.play(AssetSource('assets/sounds/$soundName.mp3'));
          played = true;
          print('✅ Notification sound played successfully (method 3): $soundName');
        } catch (e) {
          print('❌ Method 3 failed: $e');
        }
      }
      
      if (!played) {
        print('❌ All methods failed to play sound: $soundName');
        // Trigger haptic feedback as fallback
        try {
          HapticFeedback.mediumImpact();
          print('🔊 Triggered haptic feedback as fallback');
        } catch (e) {
          print('❌ Haptic feedback also failed: $e');
        }
      }
      
      // Set volume and auto-stop
      if (played) {
        await _currentPlayer!.setVolume(0.8);
        
        // Auto-stop after 3 seconds
        Future.delayed(Duration(seconds: 3), () async {
          await _stopCurrentPlayer();
        });
      }
      
    } catch (e) {
      print('❌ Critical error in playNotificationSound: $e');
      await _stopCurrentPlayer();
    }
  }

  /// Play ezan sound if enabled
  static Future<void> _playEzanSoundIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool ezanEnabled = prefs.getBool('ezan_sound_enabled') ?? false;
      
      if (ezanEnabled) {
        final ezanSound = prefs.getString('ezan_sound') ?? 'azan_traditional';
        await playEzanSound(ezanSound);
      }
    } catch (e) {
      print('Error playing ezan sound: $e');
    }
  }

  /// Play ezan sound with improved error handling
  static Future<void> playEzanSound(String soundName) async {
    await _stopCurrentPlayer();
    
    try {
      _currentPlayer = AudioPlayer();
      
      bool played = false;
      
      // Try multiple methods to play the ezan sound
      try {
        await _currentPlayer!.play(AssetSource('sounds/$soundName.mp3'));
        played = true;
        print('✅ Ezan sound played successfully (method 1): $soundName');
      } catch (e) {
        print('❌ Ezan method 1 failed: $e');
      }
      
      if (!played) {
        try {
          await _currentPlayer!.setSource(AssetSource('sounds/$soundName.mp3'));
          await _currentPlayer!.resume();
          played = true;
          print('✅ Ezan sound played successfully (method 2): $soundName');
        } catch (e) {
          print('❌ Ezan method 2 failed: $e');
        }
      }
      
      if (!played) {
        try {
          await _currentPlayer!.play(AssetSource('assets/sounds/$soundName.mp3'));
          played = true;
          print('✅ Ezan sound played successfully (method 3): $soundName');
        } catch (e) {
          print('❌ Ezan method 3 failed: $e');
        }
      }
      
      if (!played) {
        print('❌ All ezan methods failed: $soundName');
        HapticFeedback.heavyImpact();
      }
      
      if (played) {
        await _currentPlayer!.setVolume(0.9);
        
        // Auto-stop after 10 seconds for ezan
        Future.delayed(Duration(seconds: 10), () async {
          await _stopCurrentPlayer();
        });
      }
      
    } catch (e) {
      print('❌ Critical error in playEzanSound: $e');
      await _stopCurrentPlayer();
    }
  }

  /// Stop current player safely
  static Future<void> _stopCurrentPlayer() async {
    if (_currentPlayer != null) {
      try {
        await _currentPlayer!.stop();
        await _currentPlayer!.dispose();
        _currentPlayer = null;
      } catch (e) {
        print('Error stopping current player: $e');
        _currentPlayer = null;
      }
    }
  }

  /// Send test notification with improved feedback
  static Future<void> sendTestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationSound = prefs.getString('notification_sound') ?? 'bell_soft';
      
      // Schedule immediate notification
      await _scheduleNotification(
        id: 9999,
        title: 'Test Bildirimi 📱',
        body: 'Bu bir test bildirimidir! Bildirim sistemi çalışıyor. Ses: $notificationSound',
        scheduledTime: DateTime.now().add(Duration(seconds: 1)),
        sound: notificationSound,
        payload: 'test|notification',
      );
      
      // Also play the sound immediately for testing
      await playNotificationSound(notificationSound);
      
      print('✅ Test notification scheduled and sound attempted');
    } catch (e) {
      print('❌ Error sending test notification: $e');
      rethrow; // Re-throw to be caught by UI
    }
  }

  /// Test ezan sound
  static Future<void> testEzanSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ezanSound = prefs.getString('ezan_sound') ?? 'azan_traditional';
      
      await playEzanSound(ezanSound);
      print('✅ Testing ezan sound: $ezanSound');
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
  static Future<void> setReminderTime(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
    
    // Reschedule notifications with new reminder time
    final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    if (notificationsEnabled) {
      await schedulePrayerNotifications();
    }
  }

  /// Set reminder minutes
  static Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
  }

  /// Set notification sound
  static Future<void> setNotificationSound(String soundKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', soundKey);
  }

  /// Set ezan sound enabled
  static Future<void> setEzanSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ezan_sound_enabled', enabled);
  }

  /// Set ezan sound
  static Future<void> setEzanSound(String soundKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ezan_sound', soundKey);
  }

  /// Get current settings
  static Future<Map<String, dynamic>> getCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'notifications_enabled': prefs.getBool('notifications_enabled') ?? false,
      'reminder_minutes': prefs.getInt('reminder_minutes') ?? 5,
      'notification_sound': prefs.getString('notification_sound') ?? 'bell_soft',
      'ezan_sound_enabled': prefs.getBool('ezan_sound_enabled') ?? false,
      'ezan_sound': prefs.getString('ezan_sound') ?? 'azan_traditional',
    };
  }
}
