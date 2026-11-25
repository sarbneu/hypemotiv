/// Camera-proof checks for the wake-up alarm.
///
/// Every proof must be a fresh, non-blank camera capture, and the second photo
/// must be a genuinely different capture from the first. For the toothbrush
/// target an optional backend detector adds an object check; when the detector
/// is not configured the deterministic checks alone are sufficient.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:hypemotiv/services/hype_api.dart';

class ProofSignature {
  const ProofSignature({
    required this.hash,
    required this.capturedAt,
    required this.brightness,
    required this.variance,
  });

  final String hash;
  final DateTime capturedAt;
  final double brightness;
  final double variance;
}

class ProofResult {
  const ProofResult({
    required this.ok,
    required this.message,
    this.signature,
  });

  final bool ok;
  final String message;
  final ProofSignature? signature;
}

class ProofVerificationService {
  /// A photo taken more than two minutes ago is not a live proof.
  static const Duration maxPhotoAge = Duration(minutes: 2);

  /// Two captures must be at least eight seconds apart and visually different.
  static const Duration minGap = Duration(seconds: 8);
  static const int minHashDistance = 12;

  /// Minimum detector confidence accepted for the toothbrush target.
  static const double minToothbrushConfidence = 0.5;

  Future<ProofResult> verify(File photo, String target) async {
    if (!await photo.exists()) {
      return const ProofResult(ok: false, message: 'No photo was found');
    }

    final DateTime modified = (await photo.stat()).modified;
    final Duration age = DateTime.now().difference(modified);
    if (age > maxPhotoAge || age.inSeconds < -30) {
      return const ProofResult(
        ok: false,
        message: 'That photo is not fresh. Take a new one now.',
      );
    }

    final Uint8List bytes = await photo.readAsBytes();
    final Completer<ui.Image> decoded = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image image) => decoded.complete(image));
    final ui.Image image = await decoded.future;
    final ByteData? pixelData = await image.toByteData();
    if (pixelData == null) {
      image.dispose();
      return const ProofResult(ok: false, message: 'Could not read the photo');
    }
    final Uint8List pixels = pixelData.buffer.asUint8List(
      pixelData.offsetInBytes,
      pixelData.lengthInBytes,
    );

    final List<double> luminance = <double>[];
    for (int y = 0; y < image.height; y += 16) {
      for (int x = 0; x < image.width; x += 16) {
        final int index = (y * image.width + x) * 4;
        final int r = pixels[index];
        final int g = pixels[index + 1];
        final int b = pixels[index + 2];
        luminance.add(0.299 * r + 0.587 * g + 0.114 * b);
      }
    }
    image.dispose();
    if (luminance.isEmpty) {
      return const ProofResult(ok: false, message: 'Could not read the photo');
    }

    double sum = 0;
    for (final double value in luminance) {
      sum += value;
    }
    final double mean = sum / luminance.length;
    double varianceSum = 0;
    for (final double value in luminance) {
      varianceSum += (value - mean) * (value - mean);
    }
    final double variance = varianceSum / luminance.length;

    if (mean < 20) {
      return const ProofResult(
        ok: false,
        message: 'Photo is too dark. Turn on a light and try again.',
      );
    }
    if (variance < 50) {
      return const ProofResult(
        ok: false,
        message: 'Photo looks blank. Point the camera at the target.',
      );
    }

    final String hash = _averageHash(pixels, image.width, image.height, mean);
    final ProofSignature signature = ProofSignature(
      hash: hash,
      capturedAt: modified,
      brightness: mean,
      variance: variance,
    );

    if (target.trim().toLowerCase().contains('toothbrush')) {
      return _verifyToothbrush(
        photo: photo,
        target: target,
        signature: signature,
      );
    }
    return ProofResult(
      ok: true,
      message: 'Fresh camera photo accepted for $target',
      signature: signature,
    );
  }

  Future<ProofResult> _verifyToothbrush({
    required File photo,
    required String target,
    required ProofSignature signature,
  }) async {
    final Map<String, dynamic>? result =
        await HypeApi().detectToothbrush(photo);

    if (result != null && result['configured'] == false) {
      // Server reachable, but no detector model installed: keep the
      // deterministic pass and say why the object check was skipped.
      return ProofResult(
        ok: true,
        message: 'Fresh camera photo accepted for $target '
            '(toothbrush detector unavailable on the backend; '
            'deterministic checks passed)',
        signature: signature,
      );
    }
    if (result == null) {
      return const ProofResult(
        ok: false,
        message: 'Toothbrush could not be verified: the detector did not '
            'respond. Check the connection and try again.',
      );
    }

    final dynamic rawDetections = result['detections'];
    final List<DetectionBox> boxes = rawDetections is List
        ? rawDetections.whereType<DetectionBox>().toList()
        : <DetectionBox>[];
    DetectionBox? best;
    for (final DetectionBox box in boxes) {
      if (box.confidence >= minToothbrushConfidence &&
          (best == null || box.confidence > best.confidence)) {
        best = box;
      }
    }

    final String seen = boxes.isEmpty
        ? 'no detections returned'
        : boxes
            .map(
              (DetectionBox b) =>
                  '${b.className} ${(b.confidence * 100).toStringAsFixed(0)}%',
            )
            .join(', ');

    if (best == null) {
      return ProofResult(
        ok: false,
        message: 'No toothbrush detected clearly enough ($seen). '
            'Point the camera at the toothbrush and try again.',
      );
    }
    return ProofResult(
      ok: true,
      message: 'Fresh camera photo accepted for $target; detected '
          '${best.className} at '
          '${(best.confidence * 100).toStringAsFixed(0)}% confidence',
      signature: signature,
    );
  }

  /// True only when the second photo is a separate, visually different capture.
  bool isDistinctCapture(ProofSignature first, ProofSignature second) {
    final Duration gap = second.capturedAt.difference(first.capturedAt);
    if (gap < minGap) return false;
    return hashDistance(first.hash, second.hash) >= minHashDistance;
  }

  static int hashDistance(String a, String b) {
    if (a.length != b.length) return 64;
    int distance = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) distance++;
    }
    return distance;
  }

  static String _averageHash(
    Uint8List pixels,
    int width,
    int height,
    double mean,
  ) {
    const int grid = 8;
    final StringBuffer hash = StringBuffer();
    for (int gy = 0; gy < grid; gy++) {
      for (int gx = 0; gx < grid; gx++) {
        final int x = ((gx + 0.5) * width / grid).clamp(0, width - 1).toInt();
        final int y = ((gy + 0.5) * height / grid).clamp(0, height - 1).toInt();
        final int index = (y * width + x) * 4;
        final double luminance =
            0.299 * pixels[index] +
            0.587 * pixels[index + 1] +
            0.114 * pixels[index + 2];
        hash.write(luminance >= mean ? '1' : '0');
      }
    }
    return hash.toString();
  }
}
