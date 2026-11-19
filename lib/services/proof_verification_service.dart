/// Checks that a wake-up proof photo is fresh, non-blank, and shows the target.
///
/// Object labels come from ML Kit on the device. If the model is unavailable,
/// the basic freshness and image checks still apply.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ProofResult {
  const ProofResult({
    required this.ok,
    required this.message,
    this.labels = const <String>[],
  });

  final bool ok;
  final String message;
  final List<String> labels;
}

class ProofVerificationService {
  static const Map<String, List<String>> _keywords = <String, List<String>>{
    'sink': <String>['sink', 'basin', 'faucet', 'tap', 'wash'],
    'toothbrush': <String>['toothbrush', 'brush', 'teeth', 'toothpaste'],
  };

  Future<ProofResult> verify(File photo, String target) async {
    if (!await photo.exists()) {
      return const ProofResult(ok: false, message: 'No photo was found');
    }

    final DateTime modified = (await photo.stat()).modified;
    final Duration age = DateTime.now().difference(modified);
    if (age.inMinutes > 10) {
      return const ProofResult(
        ok: false,
        message: 'Photo is too old. Take a new one now.',
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
    double sum = 0;
    double sumSquares = 0;
    int count = 0;
    for (int y = 0; y < image.height; y += 20) {
      for (int x = 0; x < image.width; x += 20) {
        final int index = (y * image.width + x) * 4;
        final int r = pixels[index];
        final int g = pixels[index + 1];
        final int b = pixels[index + 2];
        final double luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        sum += luminance;
        sumSquares += luminance * luminance;
        count++;
      }
    }
    image.dispose();
    if (count == 0) {
      return const ProofResult(ok: false, message: 'Could not read the photo');
    }

    final double mean = sum / count;
    final double variance = (sumSquares / count) - (mean * mean);
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

    ImageLabeler? labeler;
    try {
      labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.3),
      );
      final List<ImageLabel> labels =
          await labeler.processImage(InputImage.fromFilePath(photo.path));
      final List<String> texts = labels
          .map((ImageLabel label) => label.label.toLowerCase())
          .toList();
      final List<String> wanted = _keywords[target] ?? const <String>[];
      final bool matched = texts.any(
        (String text) => wanted.any((String word) => text.contains(word)),
      );
      if (matched) {
        return ProofResult(
          ok: true,
          message: 'Photo accepted for $target',
          labels: texts,
        );
      }
      return ProofResult(
        ok: false,
        message: 'Could not see a $target. Saw: ${texts.take(3).join(', ')}',
        labels: texts,
      );
    } catch (_) {
      return const ProofResult(
        ok: true,
        message: 'Basic photo check passed (object model unavailable)',
      );
    } finally {
      await labeler?.close();
    }
  }
}
