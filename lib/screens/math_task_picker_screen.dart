library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/math_task_service.dart';

class MathTaskPickerScreen extends StatefulWidget {
  const MathTaskPickerScreen({super.key});

  @override
  State<MathTaskPickerScreen> createState() => _MathTaskPickerScreenState();
}

class _MathTaskPickerScreenState extends State<MathTaskPickerScreen> {
  final MathTaskService _service = MathTaskService();
  final TextEditingController _question = TextEditingController();
  final TextEditingController _answer = TextEditingController();
  String _difficulty = 'Easy';
  List<MathProblem> _samples = const <MathProblem>[];
  List<CustomMathQuestion> _custom = const <CustomMathQuestion>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String difficulty = await _service.difficulty();
    final List<CustomMathQuestion> custom = await _service.customQuestions();
    if (!mounted) return;
    setState(() {
      _difficulty = difficulty;
      _custom = custom;
      _loading = false;
    });
    await _preview();
  }

  Future<void> _add() async {
    final String question = _question.text.trim();
    final int? answer = int.tryParse(_answer.text.trim());
    if (question.isEmpty || answer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a question and a numeric answer')),
      );
      return;
    }
    await _service.addCustom(question, answer);
    _question.clear();
    _answer.clear();
    await _load();
  }

  Future<void> _preview() async {
    final List<MathProblem> samples = <MathProblem>[];
    for (int i = 0; i < 3; i++) {
      samples.add(await _service.nextProblem());
    }
    if (!mounted) return;
    setState(() => _samples = samples);
  }

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maths options')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                const Text(
                  'Difficulty',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    for (final String level in MathTaskService.difficulties)
                      ButtonSegment<String>(
                        value: level,
                        label: Text(level),
                      ),
                  ],
                  selected: <String>{_difficulty},
                  onSelectionChanged: (Set<String> selected) async {
                    if (selected.isEmpty) return;
                    final String value = selected.first;
                    setState(() => _difficulty = value);
                    await _service.setDifficulty(value);
                    await _preview();
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Show 3 different questions'),
                  onPressed: _preview,
                ),
                ..._samples.map(
                  (MathProblem problem) => ListTile(
                    title: Text(problem.question),
                    subtitle: Text('Answer: ${problem.answer}'),
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Custom questions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _question,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'What is 7 + 5?',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _answer,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    hintText: '12',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add question'),
                  onPressed: _add,
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < _custom.length; i++)
                  ListTile(
                    title: Text(_custom[i].question),
                    subtitle: Text('Answer: ${_custom[i].answer}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await _service.removeCustom(i);
                        await _load();
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
