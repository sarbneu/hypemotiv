/// Sound service - fetches sounds from myinstants.com API
/// Custom sound library for meme alarms
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

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
  static const String _apiBase = 'https://myinstants.com';
  final Map<String, List<Sound>> _cachedSounds = {};

  /// Fetch sounds from myinstants.com
  Future<List<Sound>> fetchSounds({String category = 'all', int limit = 50}) async {
    if (_cachedSounds.containsKey(category) && _cachedSounds[category]!.length >= limit) {
      return _cachedSounds[category]!;
    }

    try {
      // Search for sounds from myinstants
      final response = await http.get(
        Uri.parse('$_apiBase/search/?q=&limit=$limit&format=json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final sounds = <Sound>[];

        for (final item in data) {
          // MyInstants API returns different formats, handle both
          if (item is Map<String, dynamic>) {
            final sound = Sound(
              id: item['_id'] ?? item['id'] ?? '',
              name: item['name'] ?? item['title'] ?? 'Unknown',
              url: item['url'] ?? '',
              category: item['category'] ?? 'General',
              imageUrl: item['imageUrl'] ?? item['logo'] ?? '',
              createdAt: item['createdAt'] != null
                  ? DateTime.parse(item['createdAt'].toString())
                  : DateTime.now(),
            );
            sounds.add(sound);
          }
        }

        // Cache by category
        if (category != 'all' || sounds.isNotEmpty) {
          _cachedSounds['all'] = sounds;
        }

        return sounds.take(limit).toList();
      } else {
        // Fallback to demo sounds if API fails
        return _getDemoSounds();
      }
    } catch (e) {
      return _getDemoSounds();
    }
  }

  /// Offline sounds. All URLs are real myinstants.com media files verified
  /// with HTTP 200 + audio/mpeg (soundjay.com links used previously are 404).
  List<Sound> _getDemoSounds() {
    const String base = 'https://www.myinstants.com/media/sounds/';
    return [
      Sound(id: 'offline_bruh', name: 'Bruh Sound Effect #2',
          url: '${base}bruh-sound-effect_WstdzdM.mp3', category: 'Meme', imageUrl: ''),
      Sound(id: 'offline_oof', name: 'Roblox OOF',
          url: '${base}roblox-oof.mp3', category: 'Game', imageUrl: ''),
      Sound(id: 'offline_airhorn', name: 'Airhorn',
          url: '${base}airhorn.mp3', category: 'Alarm', imageUrl: ''),
      Sound(id: 'offline_damage', name: 'Emotional Damage',
          url: '${base}emotional-damage.mp3', category: 'Meme', imageUrl: ''),
      Sound(id: 'offline_fbi', name: 'FBI Open Up',
          url: '${base}fbi-open-up.mp3', category: 'Meme', imageUrl: ''),
      Sound(id: 'offline_wow', name: 'Wow',
          url: '${base}wow.mp3', category: 'Meme', imageUrl: ''),
      Sound(id: 'offline_bell', name: 'Morning Bell',
          url: '${base}bell.mp3', category: 'Alarm', imageUrl: ''),
    ];
  }

  /// Get sound categories
  List<String> getCategories() {
    return [
      'Alarm',
      'Game',
      'Meme',
      'Siri',
      'Mario',
      'General',
      'All',
    ];
  }

  /// Get sound by ID
  Sound? getSoundById(String id, List<Sound> sounds) {
    return sounds.firstWhere(
      (s) => s.id == id,
      orElse: () => Sound(
        id: id,
        name: 'Unknown Sound',
        url: '',
        category: 'General',
        imageUrl: '',
      ),
    );
  }

  /// Clear cache
  void clearCache() {
    _cachedSounds.clear();
  }
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

  Sound? getSoundById(String id, List<Sound> sounds) {
    return _soundService.getSoundById(id, sounds);
  }
}
