library;

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProofService {
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
