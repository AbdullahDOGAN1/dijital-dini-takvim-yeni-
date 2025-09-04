import 'package:flutter/material.dart';

class ReligiousDay {
  final String name;
  final DateTime date;
  final String hijriDate;
  final String category; // 'kandil', 'bayram', 'ozel_gun'
  final String description;
  final String importance;
  final List<String> traditions;
  final List<String> prayers;

  ReligiousDay({
    required this.name,
    required this.date,
    required this.hijriDate,
    required this.category,
    required this.description,
    required this.importance,
    required this.traditions,
    required this.prayers,
  });

  bool get isPast => date.isBefore(DateTime.now());
  bool get isToday => _isSameDay(date, DateTime.now());
  bool get isUpcoming => date.isAfter(DateTime.now());

  int get daysUntil => isUpcoming ? date.difference(DateTime.now()).inDays : 0;
  int get daysPassed => isPast ? DateTime.now().difference(date).inDays : 0;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color get categoryColor {
    switch (category) {
      case 'kandil':
        return const Color(0xFF4CAF50); // Yeşil
      case 'bayram':
        return const Color(0xFFFF9800); // Turuncu
      case 'ozel_gun':
        return const Color(0xFF2196F3); // Mavi
      default:
        return const Color(0xFF9E9E9E); // Gri
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'kandil':
        return 'Kandil';
      case 'bayram':
        return 'Bayram';
      case 'ozel_gun':
        return 'Özel Gün';
      default:
        return 'Diğer';
    }
  }

  // JSON serialization methods
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'hijriDate': hijriDate,
      'category': category,
      'description': description,
      'importance': importance,
      'traditions': traditions,
      'prayers': prayers,
    };
  }

  factory ReligiousDay.fromJson(Map<String, dynamic> json) {
    return ReligiousDay(
      name: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      hijriDate: json['hijriDate'] ?? '',
      category: json['category'] ?? 'ozel_gun',
      description: json['description'] ?? '',
      importance: json['importance'] ?? '',
      traditions: List<String>.from(json['traditions'] ?? []),
      prayers: List<String>.from(json['prayers'] ?? []),
    );
  }
}
