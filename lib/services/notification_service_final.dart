import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer_times_model.dart';
import 'prayer_api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Notification channel IDs for Android
  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'Namaz Vakti Hatırlatıcıları';
  static const String _channelDescription = 'Namaz vakitleri için hatırlatıcı bildirimleri';

  // Available sounds
  static const List<Map<String, String>> availableSounds = [
    {'key': 'bell_soft', 'name': 'Yumuşak Zil'},
    {'key': 'chime_peaceful', 'name': 'Huzurlu Çan'},
    {'key': 'notification_gentle', 'name': 'Nazik Bildirim'},
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

  /// Play notification sound using audioplayers 6.5.0 API
  static Future<void> playNotificationSound(String soundName) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundName.mp3'));
      print('Playing notification sound: $soundName');
      
      // Stop after 3 seconds to prevent long playing
      Future.delayed(Duration(seconds: 3), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      print('Error playing notification sound: $e');
      // Try alternative method
      try {
        await _audioPlayer.setSource(AssetSource('sounds/$soundName.mp3'));
        await _audioPlayer.resume();
      } catch (e2) {
        print('Alternative play method also failed: $e2');
      }
    }
  }

  /// Play ezan sound if enabled
  static Future<void> _playEzanSoundIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool ezanEnabled = prefs.getBool('ezan_sound_enabled') ?? false;
      
      if (ezanEnabled) {
        final ezanSound = prefs.getString('ezan_sound') ?? 'azan_traditional';
        await _audioPlayer.play(AssetSource('sounds/$ezanSound.mp3'));
        print('Playing ezan sound: $ezanSound');
        
        // Stop after 30 seconds
        Future.delayed(Duration(seconds: 30), () {
          _audioPlayer.stop();
        });
      }
    } catch (e) {
      print('Error playing ezan sound: $e');
    }
  }

  /// Send test notification
  static Future<void> sendTestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationSound = prefs.getString('notification_sound') ?? 'bell_soft';
      
      await _scheduleNotification(
        id: 9999,
        title: 'Test Bildirimi',
        body: 'Bu bir test bildirimidir. Ses: $notificationSound',
        scheduledTime: DateTime.now().add(Duration(seconds: 2)),
        sound: notificationSound,
        payload: 'test|notification',
      );
      
      // Also play the sound immediately
      await playNotificationSound(notificationSound);
      
      print('Test notification scheduled and sound played');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  /// Test ezan sound
  static Future<void> testEzanSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ezanSound = prefs.getString('ezan_sound') ?? 'azan_traditional';
      
      await _audioPlayer.play(AssetSource('sounds/$ezanSound.mp3'));
      print('Testing ezan sound: $ezanSound');
      
      // Stop after 10 seconds for testing
      Future.delayed(Duration(seconds: 10), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      print('Error testing ezan sound: $e');
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

  /// Set notification sound
  static Future<void> setNotificationSound(String soundKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', soundKey);
  }

  /// Set ezan sound enabled/disabled
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
