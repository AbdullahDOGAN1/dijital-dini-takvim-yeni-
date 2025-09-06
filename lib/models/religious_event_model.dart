class ReligiousEvent {
  final String name;
  final String hijriDate;
  final String gregorianDate;
  final String dayOfWeek;
  final String year;
  final DateTime parsedDate;
  final String? category;

  const ReligiousEvent({
    required this.name,
    required this.hijriDate,
    required this.gregorianDate,
    required this.dayOfWeek,
    required this.year,
    required this.parsedDate,
    this.category,
  });

  // Gün numarası (1-31)
  String get day {
    return parsedDate.day.toString().padLeft(2, '0');
  }

  // Ay adı (OCAK, ŞUBAT vs.)
  String get month {
    const months = [
      '', 'OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN',
      'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK'
    ];
    return months[parsedDate.month];
  }

  factory ReligiousEvent.fromJson(Map<String, dynamic> json, String year) {
    final gregorianDateStr = json['miladi_tarih'] as String;
    final parsedDate = _parseGregorianDate(gregorianDateStr, year);
    
    return ReligiousEvent(
      name: json['isim'] as String,
      hijriDate: json['hicri_tarih'] as String,
      gregorianDate: gregorianDateStr,
      dayOfWeek: json['gun'] as String,
      year: year,
      parsedDate: parsedDate,
      category: _categorizeEvent(json['isim'] as String),
    );
  }

  static DateTime _parseGregorianDate(String dateStr, String year) {
    try {
      // "01 OCAK-2025" formatını parse et
      final parts = dateStr.split(' ');
      if (parts.length >= 2) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1].split('-')[0];
        final month = _getMonthNumber(monthStr);
        final yearInt = int.parse(year);
        
        return DateTime(yearInt, month, day);
      }
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
    }
    
    // Fallback
    return DateTime.now();
  }

  static int _getMonthNumber(String monthName) {
    const months = {
      'OCAK': 1, 'ŞUBAT': 2, 'MART': 3, 'NİSAN': 4,
      'MAYIS': 5, 'HAZİRAN': 6, 'TEMMUZ': 7, 'AĞUSTOS': 8,
      'EYLÜL': 9, 'EKİM': 10, 'KASIM': 11, 'ARALIK': 12,
    };
    return months[monthName] ?? 1;
  }

  static String _categorizeEvent(String eventName) {
    final name = eventName.toUpperCase();
    
    if (name.contains('KANDİL')) {
      return 'kandil';
    } else if (name.contains('BAYRAM')) {
      return 'bayram';
    } else if (name.contains('AREFE')) {
      return 'arefe';
    } else if (name.contains('BAŞLANG')) {
      return 'baslangic';
    } else if (name.contains('YILBAŞI')) {
      return 'yilbasi';
    } else if (name.contains('AŞURE')) {
      return 'asure';
    }
    
    return 'diger';
  }

  // Güncel günden itibaren kalan gün sayısı
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    
    return eventDay.difference(today).inDays;
  }

  // Geçmiş mi kontrol et
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    
    return eventDay.isBefore(today);
  }

  // Bugün mü kontrol et
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    
    return eventDay.isAtSameMomentAs(today);
  }

  // Yaklaşan mı (önümüzdeki 30 gün içinde)
  bool get isUpcoming {
    return daysUntil >= 0 && daysUntil <= 30;
  }

  @override
  String toString() {
    return 'ReligiousEvent(name: $name, date: $gregorianDate, category: $category)';
  }
}

class ReligiousEventDetails {
  final String name;
  final List<String> description;
  final List<String> worshipsAndPrayers;
  final List<String> versesAndHadiths;
  final List<String> recommendations;

  const ReligiousEventDetails({
    required this.name,
    required this.description,
    required this.worshipsAndPrayers,
    required this.versesAndHadiths,
    required this.recommendations,
  });

  factory ReligiousEventDetails.fromJson(Map<String, dynamic> json) {
    return ReligiousEventDetails(
      name: json['isim'] as String? ?? '',
      description: _parseStringList(json['aciklama']),
      worshipsAndPrayers: _parseStringList(json['yapilan_ibadetler_ve_dualar']),
      versesAndHadiths: _parseStringList(json['ilgili_ayet_ve_hadisler']),
      recommendations: _parseStringList(json['tavsiyeler']),
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    } else if (data is String) {
      // String ise satırlarına böl
      return data.split('\n').where((line) => line.trim().isNotEmpty).toList();
    }
    
    return [];
  }

  // Açıklama metni olarak birleştir
  String get fullDescription {
    return description.join('\n\n');
  }

  // İbadet ve dualar metni olarak birleştir
  String get fullWorshipText {
    return worshipsAndPrayers.join('\n\n');
  }

  // Ayet ve hadisler metni olarak birleştir
  String get fullVersesText {
    return versesAndHadiths.join('\n\n');
  }

  // Tavsiyeler metni olarak birleştir
  String get fullRecommendationsText {
    return recommendations.join('\n\n');
  }

  // Kısa açıklama (ilk paragraf)
  String get shortDescription {
    return description.isNotEmpty ? description.first : '';
  }

  // Detay var mı kontrol et
  bool get hasDetails {
    return description.isNotEmpty || 
           worshipsAndPrayers.isNotEmpty || 
           versesAndHadiths.isNotEmpty || 
           recommendations.isNotEmpty;
  }

  @override
  String toString() {
    return 'ReligiousEventDetails(name: $name, sections: ${description.length + worshipsAndPrayers.length + versesAndHadiths.length + recommendations.length})';
  }
}
