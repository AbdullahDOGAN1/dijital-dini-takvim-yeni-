class FavoriteModel {
  final String id;
  final String date;
  final String title;
  final String content;
  final String type; // 'historical', 'risale', 'hadith', 'menu'
  final DateTime addedDate;

  FavoriteModel({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.type,
    required this.addedDate,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'content': content,
      'type': type,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'],
      date: json['date'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      addedDate: DateTime.parse(json['addedDate']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
