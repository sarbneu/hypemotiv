/// Real sleep tracking: start/stop a session, log a past night, review history.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/models/sleep_session.dart';
import 'package:hypemotiv/services/mic_monitor_service.dart';
import 'package:hypemotiv/services/sleep_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepTrackingSection extends StatefulWidget {
  const SleepTrackingSection({super.key});

  @override
  State<SleepTrackingSection> createState() => _SleepTrackingSectionState();
}

class SleepTrackingScreen extends StatelessWidget {
  const SleepTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep tracking')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: SleepTrackingSection(),
      ),
    );
  }
}

class _SleepTrackingSectionState extends State<SleepTrackingSection> {
  static const String _activeKey = 'sleep_active_start';
  final SleepTrackingService _service = SleepTrackingService();
  SharedPreferences? _prefs;
  DateTime? _activeStart;
  List<SleepSession> _history = const [];
  MicReading? _lastReading;
  bool _sampling = false;

  Future<void> _checkRoom() async {
    if (!mounted) return;
    setState(() => _sampling = true);
    final MicReading reading = await MicMonitorService().sample(seconds: 5);
    if (!mounted) return;
    setState(() {
      _sampling = false;
      _lastReading = reading;
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_activeKey);
    DateTime? start;
    if (stored != null) {
      start = DateTime.tryParse(stored);
      if (start == null) await _prefs?.remove(_activeKey);
    }
    if (!mounted) return;
    setState(() {
      _activeStart = start;
      _history = _service.getSleepHistory();
    });
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() => _history = _service.getSleepHistory());
  }

  Future<void> _start() async {
    final now = DateTime.now();
    await _prefs?.setString(_activeKey, now.toIso8601String());
    if (!mounted) return;
    setState(() => _activeStart = now);
  }

  Future<void> _stop() async {
    final start = _activeStart ?? DateTime.now();
    final reading = _lastReading;
    final String notes = reading != null && reading.available
        ? 'Room noise: ${reading.averageDb.toStringAsFixed(1)} dB, '
            '${reading.disturbances} disturbance(s)'
        : 'Tracked in app';
    await _service.recordSleepSession(
      start: start,
      end: DateTime.now(),
      notes: notes,
    );
    await _prefs?.remove(_activeKey);
    if (!mounted) return;
    setState(() => _activeStart = null);
    await _reload();
  }

  Future<void> _logPastNight() async {
    final bedController = TextEditingController(text: '22:30');
    final wakeController = TextEditingController(text: '06:30');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log a past night'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bedController,
              decoration: const InputDecoration(
                labelText: 'Bedtime (HH:mm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: wakeController,
              decoration: const InputDecoration(
                labelText: 'Wake time (HH:mm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;

    final bed = _parseTime(bedController.text) ?? const TimeOfDay(hour: 22, minute: 30);
    final wake = _parseTime(wakeController.text) ?? const TimeOfDay(hour: 6, minute: 30);
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day - 1, bed.hour, bed.minute);
    var end = DateTime(now.year, now.month, now.day, wake.hour, wake.minute);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));

    await _service.recordSleepSession(
      start: start,
      end: end,
      notes: 'Added manually',
    );
    await _reload();
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _format(Duration d) =>
      '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}m';

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final average = _service.getAverageSleepDuration();
    final sci = _service.getSleepConsistencyIndex();
    final last = _service.getLastSession();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bedtime_outlined, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('Sleep tracking',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _activeStart == null
                      ? 'Not tracking right now. Start when you go to bed, then stop when you wake up.'
                      : 'Tracking since ${_formatTime(_activeStart!)}. Tap stop when you wake up.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _activeStart == null ? _start : _stop,
                  icon: Icon(_activeStart == null ? Icons.play_arrow : Icons.stop),
                  label: Text(_activeStart == null ? 'Start sleep tracking' : 'Stop and save sleep'),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _logPastNight,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Log a past night manually'),
                ),
                const Divider(height: 8),
                OutlinedButton.icon(
                  onPressed: _sampling ? null : _checkRoom,
                  icon: const Icon(Icons.mic_none),
                  label: Text(
                    _sampling
                        ? 'Measuring room noise...'
                        : 'Check room noise (5 seconds)',
                  ),
                ),
                if (_lastReading != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _lastReading!.available
                          ? 'Average ${_lastReading!.averageDb.toStringAsFixed(1)} dB · '
                              '${_lastReading!.disturbances} disturbance(s) — saved with your next session'
                          : _lastReading!.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Average sleep'),
                      const SizedBox(height: 6),
                      Text(average == Duration.zero ? '—' : _format(average),
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Consistency (SCI)'),
                      const SizedBox(height: 6),
                      Text(_history.isEmpty ? '—' : '$sci%',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sleep history',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Text('No sessions yet. Start tracking or log a past night.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ))
                else
                  ..._history.map(
                    (session) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.nights_stay_outlined),
                      title: Text(
                        '${_formatTime(session.startDate)} – ${_formatTime(session.endDate)}',
                      ),
                      subtitle: Text(
                        '${_format(session.duration)} · ${session.notes.isEmpty ? 'no notes' : session.notes}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete session',
                        onPressed: () async {
                          await _service.deleteSession(session.id);
                          await _reload();
                        },
                      ),
                    ),
                  ),
                if (last != null && _history.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Last night: ${_format(last.duration)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
