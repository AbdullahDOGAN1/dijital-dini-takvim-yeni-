// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class DiyanetJsonCacheService {
  static const String _defaultBaseUrl =
      'https://raw.githubusercontent.com/AbdullahDOGAN1/dijital-dini-takvim-yeni-/main/assets/data/diyanet_cache';

  static const String _remoteBaseUrl = String.fromEnvironment(
    'DIYANET_CACHE_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static Map<String, dynamic>? _cachedPrayerWindow;
  static final Map<int, List<Map<String, dynamic>>> _cachedReligiousDays = {};

  Future<Map<String, dynamic>?> getCachedPrayerTimes({
    required String date,
    required String cityCode,
  }) async {
    try {
      final window = await _getPrayerWindow();
      final byCityCode = window['byCityCode'];
      if (byCityCode is! Map) return null;

      final cityBucket = byCityCode[cityCode];
      if (cityBucket is! Map) return null;

      // Handle both YYYY-MM-DD and DD.MM.YYYY lookups
      String queryKey = date; 
      if (date.contains('-')) {
        final p = date.split('-');
        if (p.length == 3) {
          queryKey = '${p[2]}.${p[1]}.${p[0]}';
        }
      }

      final dayData = cityBucket[queryKey] ?? cityBucket[date];
      if (dayData is! Map) return null;

      final mutableData = Map<String, dynamic>.from(dayData as Map);
      mutableData['date'] = date; // enforce YYYY-MM-DD inside for API service
      return mutableData;
    } catch (e) {
      print('❌ JSON cache: Error getting cached prayer times - $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCachedPrayerTimesRange({
    required String cityCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final window = await _getPrayerWindow();
      final byCityCode = window['byCityCode'];
      if (byCityCode is! Map) return [];

      final cityBucket = byCityCode[cityCode];
      if (cityBucket is! Map) return [];

      final start = _formatDate(startDate);
      final end = _formatDate(endDate);

      final results = <Map<String, dynamic>>[];
      for (final entry in cityBucket.entries) {
        final dateKey = entry.key.toString(); // e.g. "21.03.2026"

        // Normalize dateKey to YYYY-MM-DD
        String ymdKey = dateKey;
        if (dateKey.contains('.')) {
          final p = dateKey.split('.');
          if (p.length == 3) {
            ymdKey = '${p[2]}-${p[1]}-${p[0]}';
          }
        }

        if (ymdKey.compareTo(start) >= 0 && ymdKey.compareTo(end) <= 0) {
          final value = entry.value;
          if (value is Map) {
            final mutableValue = Map<String, dynamic>.from(value);
            mutableValue['date'] = ymdKey; // Provide expected YYYY-MM-DD for PrayerApiService
            // DO NOT override gregorianDateShort! PrayerTimesModel needs it as DD.MM.YYYY
            results.add(mutableValue);
          }
        }
      }

      results.sort((a, b) {
        final da = a['date']?.toString() ?? '';
        final db = b['date']?.toString() ?? '';
        return da.compareTo(db);
      });
      return results;
    } catch (e) {
      print('❌ JSON cache: Error getting cached prayer times range - $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCachedReligiousDays({
    required int year,
  }) async {
    final cached = _cachedReligiousDays[year];
    if (cached != null) return cached;

    final remote = await _loadRemoteReligiousDays(year);
    if (remote.isNotEmpty) {
      _cachedReligiousDays[year] = remote;
      return remote;
    }

    return const [];
  }

  Future<Map<String, dynamic>> _getPrayerWindow() async {
    if (_cachedPrayerWindow != null) return _cachedPrayerWindow!;

    final remote = await _loadRemotePrayerWindow();
    if (remote != null) {
      _cachedPrayerWindow = remote;
      return remote;
    }

    final local = await _loadLocalPrayerWindow();
    _cachedPrayerWindow = local;
    return local;
  }

  Future<Map<String, dynamic>?> _loadRemotePrayerWindow() async {
    try {
      final uri = Uri.parse('$_remoteBaseUrl/prayer_times_window.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 45));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
      return null;
    } catch (e) {
      print('❌ ERROR _loadRemotePrayerWindow failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadRemoteReligiousDays(int year) async {
    try {
      final uri = Uri.parse('$_remoteBaseUrl/religious_days_$year.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['days'] is List) {
        return List<Map<String, dynamic>>.from(decoded['days']);
      }
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>> _loadLocalPrayerWindow() async {
    try {
      final data = await rootBundle.loadString(
        'assets/data/diyanet_cache/prayer_times_window.json',
      );
      final decoded = json.decode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      print('❌ ERROR _loadLocalPrayerWindow failed: $e');
    }
    return const {'byCityCode': {}};
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
