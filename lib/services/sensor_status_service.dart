library;

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorStatus {
  const SensorStatus({
    required this.accelerometer,
    required this.cameraCount,
    required this.detector,
  });

  final bool accelerometer;
  final int cameraCount;
  final bool detector;
}

class SensorStatusService {
  Future<bool> accelerometerAvailable() async {
    final Completer<bool> found = Completer<bool>();
    StreamSubscription<AccelerometerEvent>? subscription;
    try {
      subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (!found.isCompleted) found.complete(true);
      });
      final bool ok = await found.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      await subscription.cancel();
      return ok;
    } catch (_) {
      await subscription?.cancel();
      return false;
    }
  }

  Future<int> cameraCount() async {
    try {
      return (await availableCameras()).length;
    } catch (_) {
      return 0;
    }
  }

  Future<SensorStatus> check() async {
    final bool accelerometer = await accelerometerAvailable();
    final int cameras = await cameraCount();
    final bool detector = await HypeApi().detectorConfigured();
    return SensorStatus(
      accelerometer: accelerometer,
      cameraCount: cameras,
      detector: detector,
    );
  }
}
