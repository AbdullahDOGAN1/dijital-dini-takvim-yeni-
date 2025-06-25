class DailyContentModel {
  final PageFront frontPage;
  final PageBack backPage;

  DailyContentModel({required this.frontPage, required this.backPage});
}

class PageFront {
  final HistoricalEvent historicalEvent;
  final RisaleQuote risaleQuote;

  PageFront({required this.historicalEvent, required this.risaleQuote});
}

class PageBack {
  final ContentItem dailyVerseOrHadith;
  final DailyMenu dailyMenu;

  PageBack({required this.dailyVerseOrHadith, required this.dailyMenu});
}

// --- Nested Data Classes ---

class HistoricalEvent {
  final int year;
  final String event;
  
  HistoricalEvent({required this.year, required this.event});
}

class RisaleQuote {
  final String text;
  final String source;
  
  RisaleQuote({required this.text, required this.source});
}

class ContentItem {
  final String type; // "Ayet" or "Hadis"
  final String text;
  final String source;
  
  ContentItem({required this.type, required this.text, required this.source});
}

class DailyMenu {
  final String soup;
  final String mainCourse;
  final String dessert;
  
  DailyMenu({required this.soup, required this.mainCourse, required this.dessert});
}
