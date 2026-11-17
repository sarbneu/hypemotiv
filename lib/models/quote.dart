/// Quote model for the text-to-speech motivational quote scraper.
class Quote {
  final String id;
  final String text;
  final String author;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    this.createdAt = defaultTimestamp,
  });

  static DateTime get defaultTimestamp => DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      text: json['text'] as String,
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
