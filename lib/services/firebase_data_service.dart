// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Firestore Data Service
/// 
/// This service reads cached Diyanet API data from Firebase Firestore.
/// Data is synced daily by Firebase Cloud Functions to avoid rate limits.
/// 
/// Collections Structure:
/// - prayer_times/{date} - Daily prayer times
/// - hijri_calendar/{date} - Hijri calendar data
/// - religious_days/{year} - Religious days and nights
/// - daily_content/{date} - Daily Ayet, Hadis, Dua
/// - qibla/{location} - Qibla direction
/// 
/// This enables 100K+ concurrent users without hitting Diyanet API limits.
class FirebaseDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get cached prayer times for a specific date
  /// Returns null if not found in cache
  Future<Map<String, dynamic>?> getCachedPrayerTimes({
    required String date,
    required String cityCode,
  }) async {
    try {
      final docId = '${cityCode}_$date';
      final doc = await _firestore
          .collection('prayer_times')
          .doc(docId)
          .get();

      if (doc.exists) {
        print('✅ Firebase: Prayer times found in cache for $date');
        return doc.data();
      }
      
      print('⚠️  Firebase: Prayer times not in cache for $date');
      return null;
    } catch (e) {
      print('❌ Firebase: Error getting cached prayer times - $e');
      return null;
    }
  }

  /// Get cached prayer times for a date range
  /// Useful for displaying monthly calendar
  Future<List<Map<String, dynamic>>> getCachedPrayerTimesRange({
    required String cityCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];
      
      // Query Firestore for the date range
      final snapshot = await _firestore
          .collection('prayer_times')
          .where('cityCode', isEqualTo: cityCode)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String().split('T')[0])
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String().split('T')[0])
          .orderBy('date')
          .get();

      for (var doc in snapshot.docs) {
        results.add(doc.data());
      }

      print('✅ Firebase: Found ${results.length} cached prayer times in range');
      return results;
    } catch (e) {
      print('❌ Firebase: Error getting cached prayer times range - $e');
      return [];
    }
  }

  /// Get cached Hijri calendar for a specific date
  Future<Map<String, dynamic>?> getCachedHijriCalendar({
    required String date,
  }) async {
    try {
      final doc = await _firestore
          .collection('hijri_calendar')
          .doc(date)
          .get();

      if (doc.exists) {
        print('✅ Firebase: Hijri calendar found in cache for $date');
        return doc.data();
      }
      
      print('⚠️  Firebase: Hijri calendar not in cache for $date');
      return null;
    } catch (e) {
      print('❌ Firebase: Error getting cached Hijri calendar - $e');
      return null;
    }
  }

  /// Get cached religious days for a specific year
  Future<List<Map<String, dynamic>>> getCachedReligiousDays({
    required int year,
  }) async {
    try {
      final doc = await _firestore
          .collection('religious_days')
          .doc(year.toString())
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['days'] != null && data['days'] is List) {
          final days = List<Map<String, dynamic>>.from(data['days']);
          print('✅ Firebase: Found ${days.length} religious days for $year');
          return days;
        }
      }
      
      print('⚠️  Firebase: Religious days not in cache for $year');
      return [];
    } catch (e) {
      print('❌ Firebase: Error getting cached religious days - $e');
      return [];
    }
  }

  /// Get cached daily content (Ayet, Hadis, Dua)
  Future<Map<String, dynamic>?> getCachedDailyContent({
    required String date,
  }) async {
    try {
      final doc = await _firestore
          .collection('daily_content')
          .doc(date)
          .get();

      if (doc.exists) {
        print('✅ Firebase: Daily content found in cache for $date');
        return doc.data();
      }
      
      print('⚠️  Firebase: Daily content not in cache for $date');
      return null;
    } catch (e) {
      print('❌ Firebase: Error getting cached daily content - $e');
      return null;
    }
  }

  /// Get cached Qibla direction for a location
  Future<Map<String, dynamic>?> getCachedQibla({
    required String cityCode,
  }) async {
    try {
      final doc = await _firestore
          .collection('qibla')
          .doc(cityCode)
          .get();

      if (doc.exists) {
        print('✅ Firebase: Qibla direction found in cache for $cityCode');
        return doc.data();
      }
      
      print('⚠️  Firebase: Qibla direction not in cache for $cityCode');
      return null;
    } catch (e) {
      print('❌ Firebase: Error getting cached Qibla - $e');
      return null;
    }
  }

  /// Stream of prayer times updates (real-time)
  /// Useful for automatic updates when new data is synced
  Stream<Map<String, dynamic>?> streamPrayerTimes({
    required String date,
    required String cityCode,
  }) {
    final docId = '${cityCode}_$date';
    return _firestore
        .collection('prayer_times')
        .doc(docId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Stream of daily content updates (real-time)
  Stream<Map<String, dynamic>?> streamDailyContent({
    required String date,
  }) {
    return _firestore
        .collection('daily_content')
        .doc(date)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Check cache freshness
  /// Returns true if data was updated within the last 24 hours
  Future<bool> isCacheFresh({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();

      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      if (data['lastUpdated'] == null) return false;

      final Timestamp lastUpdated = data['lastUpdated'];
      final difference = DateTime.now().difference(lastUpdated.toDate());
      
      return difference.inHours < 24;
    } catch (e) {
      print('❌ Firebase: Error checking cache freshness - $e');
      return false;
    }
  }

  /// Get metadata about last sync
  Future<Map<String, dynamic>?> getSyncMetadata() async {
    try {
      final doc = await _firestore
          .collection('_metadata')
          .doc('sync_status')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Firebase: Error getting sync metadata - $e');
      return null;
    }
  }

  /// Get list of supported cities (from cache)
  Future<List<Map<String, dynamic>>> getCachedCities({
    required String stateCode,
  }) async {
    try {
      final doc = await _firestore
          .collection('locations')
          .doc('cities_$stateCode')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['cities'] != null && data['cities'] is List) {
          return List<Map<String, dynamic>>.from(data['cities']);
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Firebase: Error getting cached cities - $e');
      return [];
    }
  }

  /// Get list of supported states (from cache)
  Future<List<Map<String, dynamic>>> getCachedStates({
    required String countryCode,
  }) async {
    try {
      final doc = await _firestore
          .collection('locations')
          .doc('states_$countryCode')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['states'] != null && data['states'] is List) {
          return List<Map<String, dynamic>>.from(data['states']);
        }
      }
      
      return [];
    } catch (e) {
      print('❌ Firebase: Error getting cached states - $e');
      return [];
    }
  }
}
