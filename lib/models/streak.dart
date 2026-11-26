library;
class Streak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActive;
  final DateTime createdAt;

  Streak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActive,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static DateTime get defaultTimestamp => DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActive': lastActive?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      userId: json['userId'] as String,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : defaultTimestamp,
    );
  }

  Streak copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActive,
  }) {
    return Streak(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt,
    );
  }
}
