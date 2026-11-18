/// Sleep tab: real sleep tracking first, then a simple sleep overview.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/sleep_tracking_screen.dart';
import 'package:hypemotiv/services/notification_service.dart';
import 'package:hypemotiv/services/sleep_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepMatrixScreen extends StatefulWidget {
  const SleepMatrixScreen({super.key});

  @override
  State<SleepMatrixScreen> createState() => _SleepMatrixScreenState();
}

class _SleepMatrixScreenState extends State<SleepMatrixScreen> {
  final SleepTrackingService _service = SleepTrackingService();
  bool _blockingOn = true;

  static const int _windDownId = 9045;
  static const String _windDownKey = 'settings_wind_down';

  @override
  void initState() {
    super.initState();
    _loadWindDown();
  }

  Future<void> _loadWindDown() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_windDownKey) ?? true;
    if (!mounted) return;
    setState(() => _blockingOn = enabled);
    if (enabled) await _scheduleWindDown();
  }

  Future<void> _scheduleWindDown() async {
    await NotificationService().scheduleDaily(
      hour: 22,
      minute: 45,
      title: 'Wind-down reminder',
      body: 'Put distracting apps away and get ready for bed.',
      id: _windDownId,
    );
  }

  Future<void> _setWindDown(bool value) async {
    setState(() => _blockingOn = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_windDownKey, value);
    if (value) {
      await _scheduleWindDown();
    } else {
      await NotificationService().cancel(_windDownId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = _service.getSleepHistory();
    final sci = _service.getSleepConsistencyIndex();
    final average = _service.getAverageSleepDuration();
    final averageText = average == Duration.zero
        ? '—'
        : '${average.inHours}h ${average.inMinutes.remainder(60).toString().padLeft(2, '0')}m';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sleep and routines', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Track your nights and keep a steady wake-up time.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 16),

            // The real, usable feature comes first.
            const SleepTrackingSection(),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your sleep pattern',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: history.isEmpty ? 0 : sci / 100,
                                strokeWidth: 9,
                                backgroundColor: scheme.surfaceContainerHighest,
                                color: scheme.primary,
                              ),
                              Text(
                                history.isEmpty ? '—' : '$sci%',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Consistency score',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              Text(
                                history.isEmpty
                                    ? 'Log a few nights to see your score'
                                    : 'Based on your last ${history.length} night(s)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.6),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text('Average sleep: $averageText',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A typical night',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Reference breakdown for a 7h 45m night',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 16),
                    const _RestRow(label: 'Deep sleep', value: '2h 14m', ratio: 0.29),
                    const SizedBox(height: 12),
                    const _RestRow(label: 'REM sleep', value: '1h 48m', ratio: 0.23),
                    const SizedBox(height: 12),
                    const _RestRow(label: 'Light sleep', value: '3h 40m', ratio: 0.48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wind-down reminder',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Pause distracting apps at 10:45 PM and keep a regular bedtime.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Wind-down reminder'),
                      subtitle: const Text('Reminder at 10:45 PM'),
                      value: _blockingOn,
                      onChanged: _setWindDown,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next wake-up plan: glass of water, then a short workout.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RestRow extends StatelessWidget {
  const _RestRow({
    required this.label,
    required this.value,
    required this.ratio,
  });

  final String label;
  final String value;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 52, child: Text(value, textAlign: TextAlign.right)),
      ],
    );
  }
}
