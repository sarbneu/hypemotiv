/// HypeMotiv extended API client.
///
/// Adds the three capabilities that the base Oracle REST bridge does not have:
///   1. myinstants.com sound scraping  (GET  /api/sounds?q=)
///   2. Oracle BLOB file storage       (POST /api/files/upload, GET /api/files/:id)
///   3. Video -> audio ripper          (POST /api/rip)
///   4. Node/email delivery            (POST /api/email/send)
///
/// Every method is network-fail-safe: the UI keeps working offline and shows
/// local/demo data instead of crashing when the Node backend is not running.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/oracle_config.dart';
import 'sound_service.dart';

class HypeApi {
  static final HypeApi _instance = HypeApi._internal();
  factory HypeApi() => _instance;
  HypeApi._internal();

  static String get base => OracleConfig.apiBaseUrl;

  /// On Flutter Web, audioplayers sets crossOrigin=anonymous. myinstants.com
  /// has no CORS header, so route its media through our backend proxy.
  /// Native platforms play the direct URL (works even with no backend).
  static String playableUrl(String url) {
    if (!kIsWeb) return url;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'www.myinstants.com') return url;
    return '$base/sounds/proxy?url=${Uri.encodeComponent(url)}';
  }

  static const Duration _timeout = Duration(seconds: 20);

  /// Connectivity check. Returns true only when the Node backend is reachable.
  Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Search myinstants.com through the backend scraper.
  /// Falls back to the bundled offline sound list if the backend is down.
  Future<List<Sound>> fetchSounds({String query = '', int limit = 50}) async {
    try {
      final uri = Uri.parse('$base/sounds').replace(
        queryParameters: {'q': query, 'limit': '$limit'},
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['sounds'] as List<dynamic>?) ?? const [];
        final sounds = list
            .whereType<Map>()
            .map((e) => Sound.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (sounds.isNotEmpty) return sounds.take(limit).toList();
      }
    } catch (_) {
      // offline
    }
    return SoundService().fetchSounds(limit: limit);
  }

  /// Upload a local file (meme audio, proof photo, ripped audio) into Oracle
  /// as a BLOB. Returns the public download URL, or null on failure.
  Future<String?> uploadFile(
    File file, {
    String userId = 'demo',
    String kind = 'audio',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/files/upload'),
      );
      request.fields['userId'] = userId;
      request.fields['kind'] = kind;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      }
    } catch (_) {
      // offline
    }
    return null;
  }

  /// Paste a TikTok / Reels / YouTube / direct-media URL and get back an
  /// Oracle-hosted audio URL. Returns null when the backend cannot rip it.
  Future<String?> ripAudio(String url, {String userId = 'demo'}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$base/rip'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url, 'userId': userId}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      }
    } catch (_) {
      // offline
    }
    return null;
  }

  /// Send an accountability email through the Node/nodemailer endpoint.
  /// Returns true on success.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$base/email/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'to': to,
              'subject': subject,
              'body': body,
            }),
          )
          .timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
