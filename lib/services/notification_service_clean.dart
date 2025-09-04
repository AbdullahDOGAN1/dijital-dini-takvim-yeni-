import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:path_provider/path_provider.dart';
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

  /// Add a custom sound file
  static Future<bool> addCustomSound({
    required String filePath,
    required String displayName,
    required String soundType, // 'notification' or 'ezan'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> customSounds = prefs.getStringList('custom_sounds') ?? [];
      
      // Get app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String customSoundsDir = '${appDocDir.path}/custom_sounds';
      
      // Create custom sounds directory if it doesn't exist
      final Directory customDir = Directory(customSoundsDir);
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }
      
      // Copy file to app directory with unique name
      final File sourceFile = File(filePath);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${displayName.replaceAll(' ', '_')}.mp3';
      final String targetPath = '$customSoundsDir/$fileName';
      
      await sourceFile.copy(targetPath);
      
      // Save sound info to preferences
      // Format: "filename|display_name|type"
      final String soundInfo = '$fileName|$displayName|$soundType';
      customSounds.add(soundInfo);
      
      await prefs.setStringList('custom_sounds', customSounds);
      
      print('✅ Custom sound added successfully: $displayName');
      return true;
    } catch (e) {
      print('❌ Error adding custom sound: $e');
      return false;
    }
  }

  /// Remove a custom sound
  static Future<bool> removeCustomSound(String soundKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> customSounds = prefs.getStringList('custom_sounds') ?? [];
      
      // Find and remove the sound
      customSounds.removeWhere((sound) => sound.startsWith(soundKey));
      
      await prefs.setStringList('custom_sounds', customSounds);
      
      // Try to delete the actual file
      try {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final File soundFile = File('${appDocDir.path}/custom_sounds/$soundKey.mp3');
        if (await soundFile.exists()) {
          await soundFile.delete();
        }
      } catch (e) {
        print('⚠️ Could not delete sound file: $e');
      }
      
      print('✅ Custom sound removed: $soundKey');
      return true;
    } catch (e) {
      print('❌ Error removing custom sound: $e');
      return false;
    }
  }

  /// Get current notification settings
  static Future<Map<String, dynamic>> getCurrentSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'notifications_enabled': prefs.getBool('notifications_enabled') ?? false,
        'reminder_minutes': prefs.getInt('reminder_minutes') ?? 5,
        'notification_sound': prefs.getString('notification_sound') ?? 'bell_soft',
        'ezan_sound_enabled': prefs.getBool('ezan_sound_enabled') ?? false,
        'ezan_sound': prefs.getString('ezan_sound') ?? 'azan_traditional',
        'custom_reminder_minutes': prefs.getInt('custom_reminder_minutes') ?? 5,
        'use_custom_minutes': prefs.getBool('use_custom_minutes') ?? false,
      };
    } catch (e) {
      print('❌ Error getting current settings: $e');
      return {};
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

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
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
      final prayers = [
        {'name': 'İmsak', 'time': prayerTimes.imsak},
        {'name': 'Gün Doğumu', 'time': prayerTimes.gunes},
        {'name': 'Öğle', 'time': prayerTimes.ogle},
        {'name': 'İkindi', 'time': prayerTimes.ikindi},
        {'name': 'Akşam', 'time': prayerTimes.aksam},
        {'name': 'Yatsı', 'time': prayerTimes.yatsi},
      ];

      int notificationId = 1;
      
      for (final prayer in prayers) {
        final prayerName = prayer['name'] as String;
        final prayerTimeStr = prayer['time'] as String;
        
        // Parse prayer time
        final timeParts = prayerTimeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          
          if (hour != null && minute != null) {
            final prayerDateTime = DateTime(today.year, today.month, today.day, hour, minute);
            
            // Skip if prayer time has already passed
            if (prayerDateTime.isAfter(now)) {
              // Schedule reminder notification
              final reminderTime = prayerDateTime.subtract(Duration(minutes: reminderMinutes));
              if (reminderTime.isAfter(now)) {
                await _scheduleNotification(
                  id: notificationId++,
                  title: '$prayerName Vakti Yaklaşıyor',
                  body: '$reminderMinutes dakika sonra $prayerName vakti ($prayerTimeStr)',
                  scheduledTime: reminderTime,
                  payload: '$prayerName|$prayerTimeStr|reminder',
                );
              }
              
              // Schedule exact time notification
              await _scheduleNotification(
                id: notificationId++,
                title: '$prayerName Vakti',
                body: '$prayerName vakti girdi ($prayerTimeStr)',
                scheduledTime: prayerDateTime,
                payload: '$prayerName|$prayerTimeStr|exact_time',
              );
            }
          }
        }
      }
      
      print('✅ Prayer notifications scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling prayer notifications: $e');
    }
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
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      final tz.TZDateTime tzScheduledTime = _convertToTZDateTime(scheduledTime);
      
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

  /// Improved sound playing with better error handling and custom sound support
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
          final String soundPath = '${appDir.path}/custom_sounds/$soundName.mp3';
          final File soundFile = File(soundPath);
          
          if (await soundFile.exists()) {
            await _currentPlayer!.play(DeviceFileSource(soundPath));
            played = true;
            print('✅ Custom notification sound played: $soundName');
          } else {
            // Try with different extension
            final String soundPathWav = '${appDir.path}/custom_sounds/$soundName.wav';
            final File soundFileWav = File(soundPathWav);
            if (await soundFileWav.exists()) {
              await _currentPlayer!.play(DeviceFileSource(soundPathWav));
              played = true;
              print('✅ Custom notification sound played (wav): $soundName');
            } else {
              print('❌ Custom sound file not found: $soundPath');
            }
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
      final bool ezanSoundEnabled = prefs.getBool('ezan_sound_enabled') ?? false;
      
      if (ezanSoundEnabled) {
        final String ezanSound = prefs.getString('ezan_sound') ?? 'azan_traditional';
        await playEzanSound(ezanSound);
        print('✅ Ezan sound triggered: $ezanSound');
      } else {
        print('🔇 Ezan sound disabled');
      }
    } catch (e) {
      print('❌ Error playing ezan sound: $e');
    }
  }

  /// Play ezan sound with improved error handling and custom sound support
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
        // Play custom sound from documents directory
        try {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String soundPath = '${appDir.path}/custom_sounds/$soundName.mp3';
          final File soundFile = File(soundPath);
          
          if (await soundFile.exists()) {
            await _currentPlayer!.play(DeviceFileSource(soundPath));
            played = true;
            print('✅ Custom ezan sound played: $soundName');
          } else {
            // Try with different extension
            final String soundPathWav = '${appDir.path}/custom_sounds/$soundName.wav';
            final File soundFileWav = File(soundPathWav);
            if (await soundFileWav.exists()) {
              await _currentPlayer!.play(DeviceFileSource(soundPathWav));
              played = true;
              print('✅ Custom ezan sound played (wav): $soundName');
            } else {
              print('❌ Custom ezan sound file not found: $soundPath');
            }
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

  /// Stop current audio player
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

  /// Send a test notification
  static Future<void> sendTestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationSound = prefs.getString('notification_sound') ?? 'bell_soft';
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _notifications.show(
        999,
        'Test Bildirimi',
        'Bu bir test bildirimidir. Bildirimler çalışıyor! 🎉',
        notificationDetails,
        payload: 'test|test|test',
      );
      
      // Also play the notification sound
      await playNotificationSound(notificationSound);
      
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Update notification settings
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (enabled) {
      await schedulePrayerNotifications();
    } else {
      await cancelAllNotifications();
    }
  }

  static Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
    
    // Reschedule with new reminder time
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    if (enabled) {
      await schedulePrayerNotifications();
    }
  }

  static Future<void> setNotificationSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', sound);
  }

  static Future<void> setEzanSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ezan_sound_enabled', enabled);
  }

  static Future<void> setEzanSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ezan_sound', sound);
  }
}
