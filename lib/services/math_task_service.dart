library;

import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MathProblem {
  const MathProblem({required this.question, required this.answer});

  final String question;
  final int answer;
}

class CustomMathQuestion {
  const CustomMathQuestion({required this.question, required this.answer});

  final String question;
  final int answer;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'question': question,
        'answer': answer,
      };

  factory CustomMathQuestion.fromJson(Map<String, dynamic> json) =>
      CustomMathQuestion(
        question: json['question']?.toString() ?? '',
        answer: int.tryParse('${json['answer']}') ?? 0,
      );
}

class MathTaskService {
  static const String difficultyKey = 'math_difficulty';
  static const String customKey = 'math_custom_questions';
  static const List<String> difficulties = <String>['Easy', 'Medium', 'Hard'];

  Future<String> difficulty() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String value = prefs.getString(difficultyKey) ?? 'Easy';
    return difficulties.contains(value) ? value : 'Easy';
  }

  Future<void> setDifficulty(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      difficultyKey,
      difficulties.contains(value) ? value : 'Easy',
    );
  }

  Future<List<CustomMathQuestion>> customQuestions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(customKey);
    if (raw == null || raw.isEmpty) return const <CustomMathQuestion>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <CustomMathQuestion>[];
      return decoded
          .whereType<Map>()
          .map(
            (Map item) => CustomMathQuestion.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((CustomMathQuestion q) => q.question.isNotEmpty)
          .toList();
    } catch (_) {
      return const <CustomMathQuestion>[];
    }
  }

  Future<void> addCustom(String question, int answer) async {
    final List<CustomMathQuestion> questions =
        await customQuestions();
    final List<CustomMathQuestion> updated =
        List<CustomMathQuestion>.from(questions)
          ..add(CustomMathQuestion(question: question.trim(), answer: answer));
    await _save(updated);
  }

  Future<void> removeCustom(int index) async {
    final List<CustomMathQuestion> questions =
        await customQuestions();
    if (index < 0 || index >= questions.length) return;
    final List<CustomMathQuestion> updated =
        List<CustomMathQuestion>.from(questions)..removeAt(index);
    await _save(updated);
  }

  Future<MathProblem> nextProblem() async {
    final List<CustomMathQuestion> custom = await customQuestions();
    if (custom.isNotEmpty) {
      final CustomMathQuestion chosen =
          custom[Random().nextInt(custom.length)];
      return MathProblem(question: chosen.question, answer: chosen.answer);
    }

    final Random random = Random();
    final String level = await difficulty();
    if (level == 'Easy') {
      final int a = 1 + random.nextInt(20);
      final int b = 1 + random.nextInt(10);
      final bool subtract = random.nextBool() && a >= b;
      return subtract
          ? MathProblem(question: '$a − $b = ?', answer: a - b)
          : MathProblem(question: '$a + $b = ?', answer: a + b);
    }
    if (level == 'Hard') {
      final int a = 11 + random.nextInt(89);
      final int b = 11 + random.nextInt(19);
      return MathProblem(question: '$a × $b = ?', answer: a * b);
    }
    final int a = 11 + random.nextInt(39);
    final int b = 2 + random.nextInt(8);
    return MathProblem(question: '$a × $b = ?', answer: a * b);
  }

  Future<void> _save(List<CustomMathQuestion> questions) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      customKey,
      jsonEncode(
        questions.map((CustomMathQuestion q) => q.toJson()).toList(),
      ),
    );
  }
}
