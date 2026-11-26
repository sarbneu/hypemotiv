library;
import 'package:flutter/material.dart';
import 'package:hypemotiv/models/task.dart';
import 'package:hypemotiv/services/checklist_service.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final ChecklistService _checklistService = ChecklistService();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    await _checklistService.seedDailyChecklist();
    if (mounted) {
      final tasks = await _checklistService.getTodayTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTask(Task task) async {
    await _checklistService.toggleTask(task.id);
    if (mounted) {
      final tasks = await _checklistService.getTodayTasks();
      setState(() {
        _tasks = tasks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Checklist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildChecklist(),
    );
  }

  Widget _buildChecklist() {
    final completed = _tasks.where((t) => t.completed).length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.yellow.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Day Progress',
                style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
              ),
              Text(
                '$completed / ${_tasks.length} completed',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return Card(
                color: task.completed
                    ? Colors.green.withValues(alpha: 0.1)
                    : const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: task.completed
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        task.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      color: task.completed
                          ? Colors.green
                          : Colors.white,
                      fontWeight: task.completed
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    task.completed ? Icons.check_circle : Icons.circle_outlined,
                    color: task.completed ? Colors.green : Colors.yellow,
                  ),
                  onTap: () => _toggleTask(task),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
