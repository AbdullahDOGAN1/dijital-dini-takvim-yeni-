import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service_fixed.dart';
import 'diyanet_prayer_service.dart';

/// Background service for continuous prayer time monitoring
class BackgroundPrayerService {
  static const String _serviceKey = 'prayer_background_service';
  
  /// Initialize and configure background service
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    
    // iOS background configuration (minimal)
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'background_prayer_service',
        initialNotificationTitle: 'Nur Vakti',
        initialNotificationContent: 'Namaz vakitleri izleniyor...',
        foregroundServiceNotificationId: 999,
      ),
    );
    
    print('🚀 Background prayer service initialized');
  }
  
  /// Start the background service
  static Future<void> startService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      
      if (!isRunning) {
        await service.startService();
        print('✅ Background prayer service started');
      } else {
        print('ℹ️ Background prayer service already running');
      }
    } catch (e) {
      print('❌ Failed to start background service: $e');
    }
  }
  
  /// Stop the background service
  static Future<void> stopService() async {
    try {
      final service = FlutterBackgroundService();
      await service.invoke('stop');
      print('🛑 Background prayer service stopped');
    } catch (e) {
      print('❌ Failed to stop background service: $e');
    }
  }
  
  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      return false;
    }
  }
}

/// Main service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only execute on Android for foreground service
  if (service is AndroidServiceInstance) {
    // Configure service for foreground execution
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  service.on('stop').listen((event) {
    service.stopSelf();
  });
  
  // Start prayer time monitoring
  Timer.periodic(Duration(minutes: 5), (timer) async {
    try {
      print('🔔 Background service: Checking prayer times...');
      
      // Check if notifications are enabled
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      
      if (!notificationsEnabled) {
        print('🔔 Notifications disabled, stopping background service');
        service.stopSelf();
        return;
      }
      
      // Re-schedule notifications if needed
      final lastScheduled = prefs.getInt('last_notification_schedule') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Re-schedule every 6 hours or if more than 6 hours passed
      if (now - lastScheduled > 6 * 60 * 60 * 1000) {
        print('🔔 Re-scheduling prayer notifications...');
        await NotificationServiceFixed.schedulePrayerNotifications();
        await prefs.setInt('last_notification_schedule', now);
      }
      
      // Update foreground notification
      if (service is AndroidServiceInstance) {
        final currentTime = DateTime.now();
        await service.setForegroundNotificationInfo(
          title: 'Nur Vakti',
          content: 'Namaz vakitleri izleniyor... (${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')})',
        );
      }
      
    } catch (e) {
      print('❌ Background service error: $e');
    }
  });
  
  print('✅ Background prayer service started successfully');
}

/// iOS background handler (limited functionality due to iOS restrictions)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  print('🍎 iOS background service executed');
  
  try {
    // Quick check and schedule (iOS allows very limited background execution)
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    
    if (notificationsEnabled) {
      // Schedule notifications for today only
      await NotificationServiceFixed.schedulePrayerNotifications();
      print('🍎 iOS: Prayer notifications updated');
    }
  } catch (e) {
    print('❌ iOS background service error: $e');
  }
  
  return true;
}
