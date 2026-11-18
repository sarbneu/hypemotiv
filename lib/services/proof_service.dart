/// Persists camera proof photos when the backend is unavailable.
library;

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProofService {
  /// Copies the camera image into the app's documents directory.
  /// Returns the local path, or null if the copy failed.
  static Future<String?> saveLocally(XFile photo) async {
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String name =
          'proof_${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
      final File destination = File('${dir.path}/$name');
      await destination.writeAsBytes(await photo.readAsBytes());
      return destination.path;
    } catch (_) {
      return null;
    }
  }
}
