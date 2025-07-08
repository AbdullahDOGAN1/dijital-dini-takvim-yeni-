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
  
  // Notification channel ID for Android
  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'Namaz Vakti Hatırlatıcıları';
  static const String _channelDescription = 'Namaz vakitleri için hatırlatıcı bildirimleri';

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
    // Navigate to prayer times screen or perform action
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

      // Get today's prayer times
      final prayerTimes = await PrayerApiService.getPrayerTimesForToday();
      final reminderMinutes = prefs.getInt('reminder_minutes') ?? 5;
      final notificationSound = prefs.getString('notification_sound') ?? 'bell_soft';

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
          
          // Only schedule if reminder time is in the future
          if (reminderTime.isAfter(now)) {
            await _scheduleNotification(
              id: notificationId++,
              title: '$prayerName Vakti Yaklaşıyor',
              body: '$prayerName vakti $reminderMinutes dakika sonra ($timeString)',
              scheduledTime: reminderTime,
              sound: notificationSound,
              payload: '$prayerName|$timeString',
            );
            
            print('Scheduled notification for $prayerName at ${reminderTime.toString()}');
          }

          // Also schedule exact prayer time notification
          if (prayerTime.isAfter(now)) {
            await _scheduleNotification(
              id: notificationId++,
              title: '$prayerName Vakti Girdi',
              body: '$prayerName vakti girmiştir. ($timeString)',
              scheduledTime: prayerTime,
              sound: notificationSound,
              payload: '$prayerName|$timeString',
            );
            
            print('Scheduled exact time notification for $prayerName at ${prayerTime.toString()}');
          }
        }
      }

      print('Scheduled ${notificationId - 1000} prayer notifications');
      
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
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: Colors.green,
      colorized: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
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

  /// Convert DateTime to TZDateTime (simplified)
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // For simplicity, using local timezone
    // In production, you might want to use timezone package
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('Cancelled all notifications');
  }

  /// Play notification sound
  static Future<void> playNotificationSound(String soundName) async {
    try {
      final soundPath = 'sounds/$soundName.mp3';
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print('Error playing notification sound: $e');
      // Fallback to system sound
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

  /// Set reminder minutes before prayer time
  static Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
    
    // Reschedule notifications with new timing
    final enabled = await areNotificationsEnabled();
    if (enabled) {
      await schedulePrayerNotifications();
    }
  }

  /// Set notification sound
  static Future<void> setNotificationSound(String soundName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', soundName);
  }

  /// Get current reminder minutes
  static Future<int> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reminder_minutes') ?? 5;
  }

  /// Get current notification sound
  static Future<String> getNotificationSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('notification_sound') ?? 'bell_soft';
  }

  /// Test notification
  static Future<void> testNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Test notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notifications.show(
      9999,
      'Test Bildirimi',
      'Namaz vakti hatırlatıcı test bildirimi',
      notificationDetails,
      payload: 'test',
    );
  }
}
