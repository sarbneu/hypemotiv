/// Streak tracking model - tracks consecutive days of app usage.
class Streak {
  final String userId;
  final int currentStreak;     // Current consecutive active days
  final int longestStreak;     // Longest streak ever
  final DateTime? lastActive;  // Last time the user was active
  final DateTime createdAt;

  Streak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActive,
    this.createdAt = defaultTimestamp,
  });

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
}
