class PrayerTime {
  final String name;
  final String time;
  final DateTime date;
  final DateTime dateTime;

  PrayerTime({
    required this.name,
    required this.time,
    required this.date,
    required this.dateTime,
  });

  factory PrayerTime.fromNameAndTime({
    required String name,
    required String time,
    required DateTime date,
  }) {
    // Parse time string (HH:MM format)
    final timeParts = time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    
    final prayerDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    return PrayerTime(
      name: name,
      time: time,
      date: date,
      dateTime: prayerDateTime,
    );
  }
}
