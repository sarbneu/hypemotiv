/// Lets the user pick an audio file from the phone and keep it in the app.
///
/// The file is copied into the app's documents folder, so it survives
/// restarts and works without the backend. Uploading to the backend is
/// optional and only adds a remote copy.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomSound {
  final String name;
  final String path;
  final String? remoteUrl;
  final String addedAt;

  const CustomSound({
    required this.name,
    required this.path,
    this.remoteUrl,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'path': path,
        'remoteUrl': remoteUrl,
        'addedAt': addedAt,
      };

  factory CustomSound.fromJson(Map<String, dynamic> json) => CustomSound(
        name: json['name'] as String? ?? 'Custom sound',
        path: json['path'] as String? ?? '',
        remoteUrl: json['remoteUrl'] as String?,
        addedAt: json['addedAt'] as String? ?? '',
      );
}

class CustomSoundService {
  static final CustomSoundService _instance = CustomSoundService._internal();
  factory CustomSoundService() => _instance;
  CustomSoundService._internal();

  static const String _key = 'hypemotiv_custom_sounds';

  Future<List<CustomSound>> list() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? const <String>[];
    return stored
        .map((String item) {
          try {
            return CustomSound.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<CustomSound>()
        .where((CustomSound sound) => sound.path.isNotEmpty)
        .toList();
  }

  /// Pick a file, copy it into the app, and save its metadata.
  /// Returns the saved sound, or null if the user cancelled.
  Future<CustomSound?> pickAndSave() async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.audio,
    );
    if (picked.isEmpty) return null;

    final PlatformFile file = picked.first;
    if (file.path == null) return null;

    final Directory dir = await getApplicationDocumentsDirectory();
    final String safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String fileName = 'custom_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final File destination = File('${dir.path}/$fileName');
    await destination.writeAsBytes(await File(file.path!).readAsBytes());

    // Optional remote copy. The local copy is what makes it work offline.
    String? remoteUrl;
    try {
      remoteUrl = await HypeApi().uploadFile(
        destination,
        userId: 'demo',
        kind: 'audio',
      );
    } catch (_) {}

    final CustomSound sound = CustomSound(
      name: file.name,
      path: destination.path,
      remoteUrl: remoteUrl,
      addedAt: DateTime.now().toIso8601String(),
    );

    final List<CustomSound> sounds = await list();
    sounds.add(sound);
    await _save(sounds);
    return sound;
  }

  Future<void> delete(CustomSound sound) async {
    final List<CustomSound> sounds = await list();
    sounds.removeWhere((CustomSound item) => item.path == sound.path);
    await _save(sounds);
    try {
      final File file = File(sound.path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _save(List<CustomSound> sounds) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      sounds.map((CustomSound sound) => jsonEncode(sound.toJson())).toList(),
    );
  }
}
