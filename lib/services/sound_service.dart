/// Sound service backed by the small pack bundled with the app.
library;

import '../utils/sound_catalog.dart';

class Sound {
  final String id;
  final String name;
  final String url;
  final String category;
  final String imageUrl;
  final DateTime? createdAt;

  Sound({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
    required this.imageUrl,
    this.createdAt,
  });

  factory Sound.fromJson(Map<String, dynamic> json) {
    return Sound(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Sound',
      url: json['url'] ?? '',
      category: json['category'] ?? 'General',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class SoundService {
  final Map<String, List<Sound>> _cachedSounds = {};

  Future<List<Sound>> fetchSounds({String category = 'all', int limit = 50}) async {
    final String key = category.toLowerCase();
    if (_cachedSounds.containsKey(key)) {
      return _cachedSounds[key]!.take(limit).toList();
    }

    final List<Sound> all = defaultSoundOptions
        .map(
          (SoundOption option) => Sound(
            id: option.name,
            name: option.name,
            url: option.url,
            category: option.name.contains('Siren') ||
                    option.name.contains('Alarm') ||
                    option.name.contains('Military')
                ? 'Alarm'
                : 'Meme',
            imageUrl: '',
          ),
        )
        .toList();
    _cachedSounds['all'] = all;
    _cachedSounds['alarm'] = all.where((Sound s) => s.category == 'Alarm').toList();
    _cachedSounds['meme'] = all.where((Sound s) => s.category == 'Meme').toList();

    final List<Sound> result = key == 'all'
        ? all
        : (_cachedSounds[key] ?? all);
    return result.take(limit).toList();
  }

  List<String> getCategories() => <String>['Alarm', 'Meme', 'All'];

  Sound? getSoundById(String id, List<Sound> sounds) {
    return sounds.firstWhere(
      (Sound s) => s.id == id,
      orElse: () => Sound(
        id: id,
        name: 'Unknown Sound',
        url: '',
        category: 'General',
        imageUrl: '',
      ),
    );
  }

  void clearCache() => _cachedSounds.clear();
}

/// Sound manager (singleton)
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final SoundService _soundService = SoundService();

  Future<List<Sound>> fetchSounds({String category = 'all', int limit = 50}) async {
    return _soundService.fetchSounds(category: category, limit: limit);
  }

  List<String> getCategories() => _soundService.getCategories();

  Sound? getSoundById(String id, List<Sound> sounds) =>
      _soundService.getSoundById(id, sounds);
}
