class DailyContentModel {
  final int gunSiraNo;
  final String miladiTarih;
  final PageFront frontPage;
  final PageBack backPage;

  DailyContentModel({
    required this.gunSiraNo,
    required this.miladiTarih,
    required this.frontPage,
    required this.backPage,
  });

  factory DailyContentModel.fromJson(Map<String, dynamic> json) {
    return DailyContentModel(
      gunSiraNo: json['gun_sira_no'],
      miladiTarih: json['miladi_tarih'],
      frontPage: PageFront.fromJson(json['sayfa_onu']),
      backPage: PageBack.fromJson(json['sayfa_arkasi']),
    );
  }
}

class PageFront {
  final HistoricalEvent historicalEvent;
  final RisaleQuote risaleQuote;

  PageFront({required this.historicalEvent, required this.risaleQuote});

  factory PageFront.fromJson(Map<String, dynamic> json) {
    return PageFront(
      historicalEvent: HistoricalEvent.fromJson(json['tarihte_bugun']),
      risaleQuote: RisaleQuote.fromJson(json['gunun_risale_metni']),
    );
  }
}

class PageBack {
  final ContentItem dailyVerseOrHadith;
  final DailyMenu dailyMenu;

  PageBack({required this.dailyVerseOrHadith, required this.dailyMenu});

  factory PageBack.fromJson(Map<String, dynamic> json) {
    return PageBack(
      dailyVerseOrHadith: ContentItem.fromJson(json['gunun_hadisi_veya_ayeti']),
      dailyMenu: DailyMenu.fromJson(json['gunun_menusu']),
    );
  }
}

// --- Nested Data Classes ---

class HistoricalEvent {
  final int year;
  final String event;
  
  HistoricalEvent({required this.year, required this.event});

  factory HistoricalEvent.fromJson(Map<String, dynamic> json) {
    return HistoricalEvent(
      year: json['yil'],
      event: json['olay'],
    );
  }
}

class RisaleQuote {
  final String text;
  final String source;
  
  RisaleQuote({required this.text, required this.source});

  factory RisaleQuote.fromJson(Map<String, dynamic> json) {
    return RisaleQuote(
      text: json['metin'],
      source: json['kaynak'],
    );
  }
}

class ContentItem {
  final String type; // "Ayet" or "Hadis"
  final String text;
  final String source;
  
  ContentItem({required this.type, required this.text, required this.source});

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      type: json['tip'],
      text: json['metin'],
      source: json['kaynak'],
    );
  }
}

class DailyMenu {
  final String soup;
  final String mainCourse;
  final String dessert;
  
  DailyMenu({required this.soup, required this.mainCourse, required this.dessert});

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      soup: json['corba'],
      mainCourse: json['ana_yemek'],
      dessert: json['tatli'],
    );
  }
}
