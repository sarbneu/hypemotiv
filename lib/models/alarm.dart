/// Core data model for the HypeMotiv alarm.
library;
class Alarm {
  final String id;
  final String title;
  final DateTime scheduledTime;
  final String audioUrl;
  final bool enabled;
  final DateTime createdAt;

  Alarm({
    required this.id,
    required this.title,
    required this.scheduledTime,
    required this.audioUrl,
    this.enabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static DateTime get defaultTimestamp => DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scheduledTime': scheduledTime.toIso8601String(),
      'audioUrl': audioUrl,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      audioUrl: json['audioUrl'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
