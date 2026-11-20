/// Screen 05 — live alarm with photo check-in.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:hypemotiv/services/notification_service.dart';
import 'package:hypemotiv/services/proof_service.dart';
import 'package:hypemotiv/services/proof_verification_service.dart';
import 'package:hypemotiv/services/task_selection_service.dart';
import 'package:hypemotiv/utils/task_catalog.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';
import 'package:image_picker/image_picker.dart';

class AlarmActiveScreen extends StatefulWidget {
  const AlarmActiveScreen({super.key});

  @override
  State<AlarmActiveScreen> createState() => _AlarmActiveScreenState();
}

class _AlarmActiveScreenState extends State<AlarmActiveScreen> {
  static const String _quote =
      "Still in bed? Your rivers have already worked out and closed deals. "
      "The Boats?!";

  Timer? _clockTimer;
  DateTime _now = DateTime(2026, 1, 1, 7, 23, 27);
  bool _disarmed = false;
  bool _uploading = false;
  int _mathA = 24;
  int _mathB = 6;
  final TextEditingController _mathController = TextEditingController();
  bool _mathSolved = false;
  int _proofStep = 0;
  List<String> _requiredTasks = wakeTasks.map((WakeTask task) => task.id).toList();

  bool get _requireMaths => _requiredTasks.contains('maths');
  bool get _requirePhoto => _requiredTasks.contains('photo');



  @override
  void initState() {
    super.initState();
    TaskSelectionService().selected().then((List<String> ids) {
      if (mounted) setState(() => _requiredTasks = ids);
    });
    final math.Random random = math.Random();
    _mathA = 11 + random.nextInt(80);
    _mathB = 3 + random.nextInt(8);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _now = _now.add(const Duration(seconds: 1)));
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _mathController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final int hour = _now.hour;
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String hh = hour12.toString().padLeft(2, '0');
    final String mm = _now.minute.toString().padLeft(2, '0');
    final String ss = _now.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss ${hour >= 12 ? 'PM' : 'AM'}';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CyberTheme.panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _checkMath() {
    final int? answer = int.tryParse(_mathController.text.trim());
    if (answer == _mathA * _mathB) {
      setState(() => _mathSolved = true);
      _toast('Maths task complete');
    } else {
      _toast('Wrong answer. Try again.');
    }
  }

  Future<void> _disarmNow(String message) async {
    setState(() => _disarmed = true);
    await AudioService().stop();
    _toast(message);
  }

  Future<void> _confirmProof() async {
    if (_requireMaths && !_mathSolved) {
      _toast('Solve the maths task first');
      return;
    }
    if (!_requirePhoto) {
      await _disarmNow('Tasks complete · Alarm stopped');
      return;
    }
    final String target = _proofStep == 0 ? 'sink' : 'toothbrush';
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (picked == null || !mounted) {
      _toast('No photo taken · Alarm still ringing');
      return;
    }

    setState(() => _uploading = true);
    final ProofResult result = await ProofVerificationService().verify(
      File(picked.path),
      target,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (!result.ok) {
      _toast(result.message);
      return;
    }

    final String? url = await HypeApi().uploadFile(
      File(picked.path),
      kind: 'proof',
    );
    if (url == null) await ProofService.saveLocally(picked);

    if (_proofStep == 0) {
      setState(() => _proofStep = 1);
      _toast('Sink photo accepted. Now show your toothbrush.');
      return;
    }
    await _disarmNow('Both photos accepted · Alarm stopped');
  }

  /// Snooze only unlocks after real phone movement (20 repetitions).
  Future<void> _snoozeWithExercise() async {
    if (_requireMaths && !_mathSolved) {
      _toast('Solve the maths task first');
      return;
    }
    final Map<String, Object> exercise = _pickExercise();
    if (exercise.isEmpty) {
      await _snooze({}, duration: const Duration(minutes: 5));
      return;
    }
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ExerciseDialog(
        label: exercise['label']! as String,
        reps: exercise['reps']! as int,
      ),
    );
    if (accepted != true || !mounted) return;
    await _snooze(
      <String, Object>{
        'label': exercise['label']!,
        'reps': exercise['reps']!,
      },
      duration: const Duration(minutes: 5),
    );
  }

  Map<String, Object> _pickExercise() {
    if (_requiredTasks.contains('jumping_jacks')) {
      return <String, Object>{'label': 'jumping jacks', 'reps': 20};
    }
    if (_requiredTasks.contains('squats')) {
      return <String, Object>{'label': 'squats', 'reps': 15};
    }
    if (_requiredTasks.contains('pushups')) {
      return <String, Object>{'label': 'push-ups', 'reps': 10};
    }
    return <String, Object>{};
  }

  Future<void> _snooze(Map<String, Object> exercise, {required Duration duration}) async {
    final DateTime wake = DateTime.now().add(duration);
    await AudioService().stop();
    await NotificationService().scheduleAlarm(
      when: wake,
      title: 'Wake up',
      body: 'Snooze is over. Get up.',
      id: wake.millisecondsSinceEpoch ~/ 1000,
    );
    if (!mounted) return;
    setState(() => _disarmed = true);
    _toast(
      'Snoozed until ${wake.hour.toString().padLeft(2, '0')}:${wake.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BrandHeader(
                    status: 'Alarm ringing',
                    trailing: 'Snooze locked',
                    statusColor: Color(0xFFF04438),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: Color(0xFF3D5AFE),
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'Playing at high volume',
                          trailing: 'High volume',
                        ),
                        const SizedBox(height: 10),
                        const Waveform(
                          color: Color(0xFF3D5AFE),
                          bars: 42,
                          height: 56,
                        ),
                        const SizedBox(height: 6),
                        const MicroText(
                          'Snooze is locked',
                          color: Color(0xFF667085),
                          fontSize: 12,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'Motivation for today',
                          trailing: 'David Goggins',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "David Goggins: Who's Gonna Carry...",
                          style: TextStyle(
                            color: Color(0xFF1F2933),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          _quote,
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      for (final WakeTask task in wakeTasks)
                        if (_requiredTasks.contains(task.id))
                          Chip(
                            label: Text(task.label),
                            visualDensity: VisualDensity.compact,
                          ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_requireMaths) ...<Widget>[
                  const SizedBox(height: 16),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SectionLabel(
                          'Wake-up maths',
                          trailing: _mathSolved ? 'Done' : 'Required',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_mathA × $_mathB = ?',
                          style: const TextStyle(
                            color: Color(0xFF1F2933),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_mathSolved)
                          const Text(
                            'Correct. Photo check-in unlocked.',
                            style: TextStyle(color: Color(0xFF12B76A)),
                          )
                        else
                          Row(
                            children: <Widget>[
                              SizedBox(
                                width: 130,
                                child: TextField(
                                  controller: _mathController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Your answer',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: _checkMath,
                                child: const Text('Check'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  ],
                  if (_requirePhoto) ...<Widget>[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 184,
                    child: CyberCard(
                      padding: EdgeInsets.zero,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFFF9FAFB),
                                  Color(0xFFFFFFFF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SectionLabel(
                                  'Photo check-in',
                                  trailing: 'Required',
                                ),
                                const Spacer(),
                                MicroText(
                                  _proofStep == 0
                                      ? 'Photo 1 of 2: show your bathroom sink'
                                      : 'Photo 2 of 2: show your toothbrush',
                                  color: const Color(0xFF1F2933),
                                  fontSize: 13,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    const Text(
                                      'Ready when you are',
                                      style: TextStyle(
                                        color: Color(0xFF3D5AFE),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    const StatusChip('Ready'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const LinearProgressIndicator(
                                  value: 0.94,
                                  minHeight: 4,
                                  color: Color(0xFF3D5AFE),
                                  backgroundColor: Color(0xFFE4E7EC),
                                ),
                              ],
                            ),
                          ),
                          const ScanOverlay(),
                        ],
                      ),
                    ),
                  ),
                  ],
                  const SizedBox(height: 18),
                  _disarmed
                      ? CyberCard(
                          glow: true,
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF12B76A),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: MicroText(
                                  'Check-in complete · Alarm stopped',
                                  color: Color(0xFF12B76A),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : NeonButton(
                          label: _uploading
                              ? 'Checking photo...'
                              : _proofStep == 0
                                  ? 'Photo 1: sink'
                                  : 'Photo 2: toothbrush',
                          icon: Icons.camera_alt,
                          onPressed: _confirmProof,
                        ),
                  const SizedBox(height: 12),
                  Text(
                    _pickExercise().isEmpty
                        ? 'Need 5 more minutes? Snooze for 5 minutes.'
                        : 'Need 5 more minutes? Do ${_pickExercise()['reps']} ${_pickExercise()['label']} first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NeonButton(
                    label: 'Snooze with 20 jumping jacks',
                    primary: false,
                    icon: Icons.fitness_center,
                    onPressed: _snoozeWithExercise,
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel(
                    'Today\'s priorities',
                    trailing: '2 tasks',
                  ),
                  const SizedBox(height: 10),
                  const _PriorityItem(
                    text: 'Drink a glass of water',
                  ),
                  const SizedBox(height: 8),
                  const _PriorityItem(text: 'Morning workout'),
                ],
              ),
            ),
          ),
          const ScanOverlay(),
        ],
      ),
    );
  }
}

class _PriorityItem extends StatelessWidget {
  const _PriorityItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.radio_button_unchecked,
              color: Color(0xFF0F766E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1F2933),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({required this.label, required this.reps});

  final String label;
  final int reps;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  StreamSubscription<AccelerometerEvent>? _subscription;
  int _reps = 0;
  double _previous = 0;
  DateTime _lastPeak = DateTime.fromMillisecondsSinceEpoch(0);
  bool _manual = false;

  static const double _threshold = 13.0;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  void _startSensors() {
    try {
      _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        final double magnitude = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        final DateTime now = DateTime.now();
        final bool rising = _previous <= _threshold && magnitude > _threshold;
        final bool cooled = now.difference(_lastPeak).inMilliseconds > 350;
        if (rising && cooled) {
          _lastPeak = now;
          if (mounted) setState(() => _reps++);
        }
        _previous = magnitude;
      });
    } catch (_) {
      _manual = true;
    }
  }

  void _addManualRep() {
    if (_reps >= widget.reps) return;
    setState(() => _reps++);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.reps} ${widget.label}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Reps detected: $_reps of ${widget.reps}'),
          const SizedBox(height: 8),
          Text(
            _manual
                ? 'Motion sensor is not available here. Tap the button for each rep.'
                : 'Move the phone with each rep.',
            style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _reps / widget.reps,
            minHeight: 6,
            color: const Color(0xFF3D5AFE),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (!_manual)
          TextButton(
            onPressed: () => setState(() => _manual = true),
            child: const Text('Manual mode'),
          ),
        TextButton(
          onPressed: _addManualRep,
          child: const Text('Count a rep'),
        ),
        FilledButton(
          onPressed: _reps >= widget.reps
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Finish'),
        ),
      ],
    );
  }
}
