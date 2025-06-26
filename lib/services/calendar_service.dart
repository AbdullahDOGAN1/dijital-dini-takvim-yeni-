import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/daily_content_model.dart';

class CalendarService {
  /// Load calendar data from local JSON file
  static Future<List<DailyContentModel>> loadCalendarData() async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/sample_calendar_data.json',
      );

      // Parse the JSON string to a List<dynamic>
      final List<dynamic> jsonList = json.decode(jsonString);

      // Convert each JSON object to DailyContentModel
      final List<DailyContentModel> calendarData = jsonList
          .map(
            (json) => DailyContentModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return calendarData;
    } catch (e) {
      // If there's an error, return an empty list and log the error
      print('Error loading calendar data: $e');
      return [];
    }
  }
}
