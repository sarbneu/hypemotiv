library;

class WakeTask {
  const WakeTask({required this.id, required this.label, required this.hint});

  final String id;
  final String label;
  final String hint;
}

const List<WakeTask> wakeTasks = <WakeTask>[
  WakeTask(
    id: 'maths',
    label: 'Maths challenge',
    hint: 'Solve a multiplication before you can stop the alarm.',
  ),
  WakeTask(
    id: 'photo',
    label: 'Photo proof',
    hint: 'Take fresh sink and toothbrush photos.',
  ),
  WakeTask(
    id: 'jumping_jacks',
    label: 'Jumping jacks',
    hint: '20 reps counted by phone movement.',
  ),
  WakeTask(
    id: 'squats',
    label: 'Squats',
    hint: '15 squats counted by phone movement.',
  ),
  WakeTask(
    id: 'pushups',
    label: 'Push-ups',
    hint: '10 push-ups counted by phone movement.',
  ),
];
