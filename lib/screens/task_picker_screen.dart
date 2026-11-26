library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/math_task_picker_screen.dart';
import 'package:hypemotiv/services/task_selection_service.dart';
import 'package:hypemotiv/utils/task_catalog.dart';

class TaskPickerScreen extends StatefulWidget {
  const TaskPickerScreen({super.key});

  @override
  State<TaskPickerScreen> createState() => _TaskPickerScreenState();
}

class _TaskPickerScreenState extends State<TaskPickerScreen> {
  final TaskSelectionService _service = TaskSelectionService();
  final Set<String> _selected = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<String> ids = await _service.selected();
    if (!mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(ids);
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _service.save(_selected.toList());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wake-up tasks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select the tasks you must finish before the alarm stops.',
                    style: TextStyle(color: Color(0xFF667085)),
                  ),
                ),
                ...wakeTasks.map(
                  (WakeTask task) => CheckboxListTile(
                    value: _selected.contains(task.id),
                    onChanged: (bool? checked) => setState(() {
                      if (checked == true) {
                        _selected.add(task.id);
                      } else {
                        _selected.remove(task.id);
                      }
                    }),
                    title: Text(task.label),
                    subtitle: Text(task.hint),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calculate),
                  label: const Text('Maths options and custom questions'),
                  onPressed: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const MathTaskPickerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _save,
            child: Text('Save tasks (${_selected.length} selected)'),
          ),
        ),
      ),
    );
  }
}
