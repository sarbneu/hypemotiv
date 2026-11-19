/// Daily checklist task model (5 tasks as per design).
library;
class Task {
  final String id;
  final String title;
  final String emoji; // e.g. "🏃", "📚", "🍳", "💧", "🧹"
  final bool completed;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    required this.emoji,
    this.completed = false,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this Task with the given fields replaced.
  Task copyWith({String? id, String? title, String? emoji, bool? completed, DateTime? completedAt}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
