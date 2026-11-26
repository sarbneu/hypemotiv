library;
class SleepSession {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final Duration duration;
  final int sleepStages;
  final bool restless;
  final String notes;
  final DateTime createdAt;

  SleepSession({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.duration,
    this.sleepStages = 0,
    this.restless = false,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static DateTime get defaultTimestamp => DateTime.now();

  Duration get sleepDuration => endDate.difference(startDate);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'duration': duration.inSeconds,
      'sleepStages': sleepStages,
      'restless': restless,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      duration: Duration(seconds: json['duration'] as int),
      sleepStages: json['sleepStages'] as int? ?? 0,
      restless: json['restless'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
