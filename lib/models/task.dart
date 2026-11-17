/// Daily checklist task model (5 tasks as per design).
class Task {
  final String id;
  final String title;
  final String emoji; // e.g. "🏃", "📚", "🍳", "💧", "🧹"
  final bool completed;
  final DateTime? completedAt;

  Task({
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
}
