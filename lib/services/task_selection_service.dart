library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hypemotiv/utils/task_catalog.dart';

class TaskSelectionService {
  static const String _key = 'wakeup_tasks';

  Future<List<String>> selected() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_key);
    if (stored == null || stored.isEmpty) {
      return wakeTasks.map((WakeTask task) => task.id).toList();
    }
    return stored;
  }

  Future<void> save(List<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids);
  }

  Future<bool> isRequired(String id) async {
    return (await selected()).contains(id);
  }
}
