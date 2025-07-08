class HijriDate {
  final String date;
  final String format;
  final String day;
  final String weekday;
  final String month;
  final String year;
  final String designation;
  final List<String> holidays;

  HijriDate({
    required this.date,
    required this.format,
    required this.day,
    required this.weekday,
    required this.month,
    required this.year,
    required this.designation,
    required this.holidays,
  });

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      date: json['date'] ?? '',
      format: json['format'] ?? '',
      day: json['day'] ?? '',
      weekday: json['weekday']?['tr'] ?? json['weekday']?['en'] ?? '',
      month: json['month']?['tr'] ?? json['month']?['en'] ?? '',
      year: json['year'] ?? '',
      designation: json['designation']?['abbreviated'] ?? '',
      holidays: json['holidays'] != null ? List<String>.from(json['holidays']) : [],
    );
  }

  String get formattedDate => '$day $month $year';
  String get shortDate => '$day/$month/$year';
}

class GeorgianDate {
  final String date;
  final String format;
  final String day;
  final String weekday;
  final String month;
  final String year;
  final String designation;

  GeorgianDate({
    required this.date,
    required this.format,
    required this.day,
    required this.weekday,
    required this.month,
    required this.year,
    required this.designation,
  });

  factory GeorgianDate.fromJson(Map<String, dynamic> json) {
    return GeorgianDate(
      date: json['date'] ?? '',
      format: json['format'] ?? '',
      day: json['day'] ?? '',
      weekday: json['weekday']?['tr'] ?? json['weekday']?['en'] ?? '',
      month: json['month']?['tr'] ?? json['month']?['en'] ?? '',
      year: json['year'] ?? '',
      designation: json['designation']?['abbreviated'] ?? '',
    );
  }

  String get formattedDate => '$day $month $year';
}

/// Model class for daily prayer times
class PrayerTimesModel {
  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;
  final String date;
  final HijriDate? hijriDate;
  final GeorgianDate? gregorianDate;

  const PrayerTimesModel({
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
    required this.date,
    this.hijriDate,
    this.gregorianDate,
  });

  /// Factory constructor to create PrayerTimesModel from JSON
  /// Supports the Aladhan API response format
  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    // Handle the nested structure of Aladhan API
    final timings = json['data']?['timings'] ?? json['timings'] ?? json;
    final dateData = json['data']?['date'] ?? json['date'] ?? {};

    // Parse Hijri and Gregorian dates if available
    HijriDate? hijriDate;
    GeorgianDate? gregorianDate;
    
    if (dateData['hijri'] != null) {
      hijriDate = HijriDate.fromJson(dateData['hijri']);
    }
    
    if (dateData['gregorian'] != null) {
      gregorianDate = GeorgianDate.fromJson(dateData['gregorian']);
    }

    // Format date from API response
    String formattedDate = '';
    if (dateData['readable'] != null) {
      formattedDate = dateData['readable'];
    } else if (gregorianDate != null) {
      formattedDate = gregorianDate.formattedDate;
    } else {
      // Fallback
      final now = DateTime.now();
      formattedDate = '${now.day} ${_getMonthName(now.month)} ${now.year}';
    }

    return PrayerTimesModel(
      imsak: _parseTime(timings['Fajr'] ?? timings['imsak'] ?? ''),
      gunes: _parseTime(timings['Sunrise'] ?? timings['gunes'] ?? ''),
      ogle: _parseTime(timings['Dhuhr'] ?? timings['ogle'] ?? ''),
      ikindi: _parseTime(timings['Asr'] ?? timings['ikindi'] ?? ''),
      aksam: _parseTime(timings['Maghrib'] ?? timings['aksam'] ?? ''),
      yatsi: _parseTime(timings['Isha'] ?? timings['yatsi'] ?? ''),
      date: formattedDate,
      hijriDate: hijriDate,
      gregorianDate: gregorianDate,
    );
  }

  /// Helper method to parse and clean prayer time strings
  /// Removes timezone info and formats consistently
  static String _parseTime(String timeString) {
    if (timeString.isEmpty) return '--:--';

    // Remove timezone info if present (e.g., "05:30 (+03)" -> "05:30")
    final cleanTime = timeString.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

    // Extract just the time part (HH:MM)
    final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(cleanTime);
    return timeMatch?.group(1) ?? cleanTime;
  }

  /// Helper method to get month name
  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Unknown';
  }

  /// Convert model to JSON (for potential caching)
  Map<String, dynamic> toJson() {
    return {
      'imsak': imsak,
      'gunes': gunes,
      'ogle': ogle,
      'ikindi': ikindi,
      'aksam': aksam,
      'yatsi': yatsi,
      'date': date,
    };
  }

  @override
  String toString() {
    return 'PrayerTimesModel(imsak: $imsak, gunes: $gunes, ogle: $ogle, ikindi: $ikindi, aksam: $aksam, yatsi: $yatsi)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PrayerTimesModel &&
        other.imsak == imsak &&
        other.gunes == gunes &&
        other.ogle == ogle &&
        other.ikindi == ikindi &&
        other.aksam == aksam &&
        other.yatsi == yatsi;
  }

  @override
  int get hashCode {
    return imsak.hashCode ^
        gunes.hashCode ^
        ogle.hashCode ^
        ikindi.hashCode ^
        aksam.hashCode ^
        yatsi.hashCode;
  }
}
