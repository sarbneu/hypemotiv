/// Microphone-based sleep environment monitor.
///
/// Samples ambient loudness for a short window and returns the average level
/// plus a disturbance count. These numbers are saved with the sleep session,
/// so the sleep screen shows measured data instead of a fabricated score.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class MicReading {
  final bool available;
  final double averageDb;
  final int disturbances;
  final String message;

  const MicReading({
    required this.available,
    required this.averageDb,
    required this.disturbances,
    required this.message,
  });
}

class MicMonitorService {
  static final MicMonitorService _instance = MicMonitorService._internal();
  factory MicMonitorService() => _instance;
  MicMonitorService._internal();

  /// Record [seconds] of ambient audio and analyse loudness.
  /// A disturbance is a half-second sample above [thresholdDb].
  Future<MicReading> sample({
    int seconds = 10,
    double thresholdDb = -35,
  }) async {
    if (kIsWeb || (Platform.isAndroid || Platform.isIOS) == false) {
      return const MicReading(
        available: false,
        averageDb: 0,
        disturbances: 0,
        message: 'Microphone monitoring is available on Android and iOS.',
      );
    }

    final AudioRecorder recorder = AudioRecorder();
    try {
      if (!await recorder.hasPermission()) {
        return const MicReading(
          available: false,
          averageDb: 0,
          disturbances: 0,
          message: 'Microphone permission was not granted.',
        );
      }

      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/hypemotiv_mic_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      final List<double> levels = <double>[];
      final sub = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 500))
          .listen((Amplitude amplitude) {
        if (amplitude.current.isFinite) levels.add(amplitude.current);
      });

      await Future<void>.delayed(Duration(seconds: seconds));
      await sub.cancel();
      await recorder.stop();

      if (levels.isEmpty) {
        return const MicReading(
          available: false,
          averageDb: 0,
          disturbances: 0,
          message: 'No microphone samples were captured.',
        );
      }

      final double average =
          levels.reduce((a, b) => a + b) / levels.length;
      final int disturbances =
          levels.where((level) => level > thresholdDb).length;

      // Remove the temporary recording; only the measurements are kept.
      try {
        final File file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      return MicReading(
        available: true,
        averageDb: average,
        disturbances: disturbances,
        message: 'Measured ${levels.length} samples over $seconds seconds.',
      );
    } catch (e) {
      debugPrint('MicMonitorService: $e');
      return MicReading(
        available: false,
        averageDb: 0,
        disturbances: 0,
        message: 'Microphone check failed: $e',
      );
    } finally {
      await recorder.dispose();
    }
  }
}
