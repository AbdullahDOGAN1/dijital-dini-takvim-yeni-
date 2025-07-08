class DailyContentModel {
  final int dayNumber;
  final String date;
  final VerseOrHadith verseOrHadith;
  final String historicalEvent;
  final RisaleQuote risaleQuote;
  final String eveningMeal;

  DailyContentModel({
    required this.dayNumber,
    required this.date,
    required this.verseOrHadith,
    required this.historicalEvent,
    required this.risaleQuote,
    required this.eveningMeal,
  });

  factory DailyContentModel.fromJson(Map<String, dynamic> json) {
    return DailyContentModel(
      dayNumber: json['gun_no'] ?? 0,
      date: json['tarih'] ?? '',
      verseOrHadith: VerseOrHadith.fromJson(json['ayet_hadis'] ?? {}),
      historicalEvent: json['tarihte_bugun'] ?? '',
      risaleQuote: RisaleQuote.fromJson(json['risale_i_nur'] ?? {}),
      eveningMeal: json['aksam_yemegi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gun_no': dayNumber,
      'tarih': date,
      'ayet_hadis': verseOrHadith.toJson(),
      'tarihte_bugun': historicalEvent,
      'risale_i_nur': risaleQuote.toJson(),
      'aksam_yemegi': eveningMeal,
    };
  }
}

class VerseOrHadith {
  final String text;
  final String source;

  VerseOrHadith({
    required this.text,
    required this.source,
  });

  factory VerseOrHadith.fromJson(Map<String, dynamic> json) {
    return VerseOrHadith(
      text: json['metin'] ?? '',
      source: json['kaynak'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metin': text,
      'kaynak': source,
    };
  }
}

class RisaleQuote {
  final String quote;
  final String source;

  RisaleQuote({
    required this.quote,
    required this.source,
  });

  factory RisaleQuote.fromJson(Map<String, dynamic> json) {
    return RisaleQuote(
      quote: json['vecize'] ?? '',
      source: json['kaynak'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vecize': quote,
      'kaynak': source,
    };
  }
}
