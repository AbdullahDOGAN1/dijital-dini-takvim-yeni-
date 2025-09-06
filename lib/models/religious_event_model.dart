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
  final String description;
  final String importance;
  final String prayers;
  final String verses;
  final String hadith;
  final String sources;

  const ReligiousEventDetails({
    required this.name,
    required this.description,
    required this.importance,
    required this.prayers,
    required this.verses,
    required this.hadith,
    required this.sources,
  });

  factory ReligiousEventDetails.fromJson(Map<String, dynamic> json) {
    final fullDescription = json['açıklama'] as String? ?? '';
    final sections = _parseDescription(fullDescription);
    
    return ReligiousEventDetails(
      name: json['isim'] as String? ?? '',
      description: sections['description'] ?? '',
      importance: sections['importance'] ?? '',
      prayers: sections['prayers'] ?? '',
      verses: sections['verses'] ?? '',
      hadith: sections['hadith'] ?? '',
      sources: sections['sources'] ?? '',
    );
  }

  static Map<String, String> _parseDescription(String fullText) {
    final sections = <String, String>{};
    
    // Açıklama kısmı (baştan CEVAP'a kadar)
    final descriptionMatch = RegExp(r'Sual:.*?CEVAP[:\s]*(.*?)(?=\n\n|\nSual:|$)', 
        dotAll: true).firstMatch(fullText);
    if (descriptionMatch != null) {
      sections['description'] = descriptionMatch.group(1)?.trim() ?? '';
    } else {
      // Alternatif: ilk paragrafı al
      final firstParagraph = fullText.split('\n\n').first;
      sections['description'] = firstParagraph;
    }

    // Önem kısmı (fazileti, kıymeti vs.)
    final importanceKeywords = ['fazileti', 'kıymeti', 'önemi', 'ehemmiyeti'];
    for (final keyword in importanceKeywords) {
      final pattern = RegExp('$keyword.*?(?=\n\n|Hadis|Dua|\$)', 
          caseSensitive: false, dotAll: true);
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        sections['importance'] = match.group(0) ?? '';
        break;
      }
    }

    // Hadis kısmı
    final hadisPattern = RegExp(r'[Hh]adis.*?(?=\n\n|Dua|Ayet|$)', dotAll: true);
    final hadisMatch = hadisPattern.firstMatch(fullText);
    if (hadisMatch != null) {
      sections['hadith'] = hadisMatch.group(0) ?? '';
    }

    // Dua kısmı
    final prayerPattern = RegExp(r'[Dd]ua.*?(?=\n\n|Hadis|Ayet|$)', dotAll: true);
    final prayerMatch = prayerPattern.firstMatch(fullText);
    if (prayerMatch != null) {
      sections['prayers'] = prayerMatch.group(0) ?? '';
    }

    // Ayet kısmı
    final versePattern = RegExp(r'[Aa]yet.*?(?=\n\n|Hadis|Dua|$)', dotAll: true);
    final verseMatch = versePattern.firstMatch(fullText);
    if (verseMatch != null) {
      sections['verses'] = verseMatch.group(0) ?? '';
    }

    // Kaynak kısmı
    final sourcePattern = RegExp(r'\[.*?\]', dotAll: true);
    final sourceMatches = sourcePattern.allMatches(fullText);
    if (sourceMatches.isNotEmpty) {
      sections['sources'] = sourceMatches.map((m) => m.group(0)).join(', ');
    }

    return sections;
  }

  @override
  String toString() {
    return 'ReligiousEventDetails(name: $name)';
  }
}
