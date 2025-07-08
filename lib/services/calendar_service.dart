import '../models/daily_content_model.dart';
import 'daily_content_service.dart';

class CalendarService {
  /// Load calendar data from local JSON file (365 days)
  static Future<List<DailyContentModel>> loadCalendarData() async {
    // Use the new DailyContentService instead of loading the old JSON
    return await DailyContentService.loadDailyContent();
  }

  /// Get content for a specific day number (1-365)
  static Future<DailyContentModel?> getContentForDay(int dayNumber) async {
    return await DailyContentService.getContentForDay(dayNumber);
  }

  /// Get current day content based on current date
  static Future<DailyContentModel?> getTodayContent() async {
    return await DailyContentService.getTodaysContent();
  }
}
