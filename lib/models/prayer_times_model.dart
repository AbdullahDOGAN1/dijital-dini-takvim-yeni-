/// Model class for daily prayer times
class PrayerTimesModel {
  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;
  final String date; // Added date field

  const PrayerTimesModel({
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
    required this.date, // Added date field
  });

  /// Factory constructor to create PrayerTimesModel from JSON
  /// Supports the Aladhan API response format
  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    // Handle the nested structure of Aladhan API
    final timings = json['data']?['timings'] ?? json['timings'] ?? json;
    final dateData = json['data']?['date'] ?? json['date'] ?? {};

    // Format date from API response
    String formattedDate = '';
    if (dateData['readable'] != null) {
      formattedDate = dateData['readable'];
    } else if (dateData['gregorian'] != null) {
      final greg = dateData['gregorian'];
      formattedDate = '${greg['day']} ${greg['month']['en']} ${greg['year']}';
    } else {
      // Fallback
      final now = DateTime.now();
      formattedDate = '${now.day} ${_getMonthName(now.month)} ${now.year}';
    }

    return PrayerTimesModel(
      imsak: _parseTime(timings['Imsak'] ?? timings['imsak'] ?? ''),
      gunes: _parseTime(
        timings['Sunrise'] ?? timings['Fajr'] ?? timings['gunes'] ?? '',
      ),
      ogle: _parseTime(timings['Dhuhr'] ?? timings['ogle'] ?? ''),
      ikindi: _parseTime(timings['Asr'] ?? timings['ikindi'] ?? ''),
      aksam: _parseTime(timings['Maghrib'] ?? timings['aksam'] ?? ''),
      yatsi: _parseTime(timings['Isha'] ?? timings['yatsi'] ?? ''),
      date: formattedDate,
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
