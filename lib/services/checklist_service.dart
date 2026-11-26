library;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/task.dart';

class ChecklistService {
  static const String boxName = 'checklist';

  late Box<Task> _box;

  ChecklistService() {
    _box = Hive.box<Task>(boxName);
  }

  Future<void> seedDailyChecklist() async {
    final currentDate = DateTime.now().formatYmd();
    final tasks = _getDefaultTasks();
    final todayBox = await _getOrCreateDailyBox(currentDate);

    if (todayBox.isEmpty) {
      for (final task in tasks) {
        final withDate = task.copyWith(
          id: '${task.id}_$currentDate',
          completed: false,
          completedAt: null,
        );
        await todayBox.put(task.id, withDate);
      }
    }
  }

  Future<void> toggleTask(String taskId) async {
    final task = _box.get(taskId);
    if (task == null) return;
    final updated = task.copyWith(
      completed: !task.completed,
      completedAt: !task.completed ? DateTime.now() : null,
    );
    await _box.put(taskId, updated);
  }

  Future<List<Task>> getTodayTasks() async {
    final today = DateTime.now().formatYmd();
    final todayBox = await Hive.openBox<Task>('_day_$today');
    return todayBox.values.cast<Task>().toList();
  }

  List<Task> getCompletedTasks() {
    return _box.values
        .where((t) => t.completed)
        .cast<Task>()
        .toList();
  }

  int get completedCount => _box.values.where((t) => t.completed).length;

  Future<void> resetAll() async {
    await _box.clear();
  }

  List<Task> _getDefaultTasks() {
    return const [
      Task(id: 'walk', title: 'Go for a walk', emoji: '🚶'),
      Task(id: 'read', title: 'Read for 30 minutes', emoji: '📚'),
      Task(id: 'eat', title: 'Have a healthy breakfast', emoji: '🍳'),
      Task(id: 'drink', title: 'Drink 2 liters of water', emoji: '💧'),
      Task(id: 'clean', title: 'Tidy up my space', emoji: '🧹'),
    ];
  }

  Future<Box<Task>> _getOrCreateDailyBox(String date) async {
    return Hive.openBox<Task>('_day_$date');
  }
}

extension DateFormatHelper on DateTime {
  String formatYmd() {
    return '$year${_twoDigits(month)}$_twoDigits(day)';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
