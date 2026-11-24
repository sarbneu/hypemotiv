/// HypeMotiv extended API client.
///
/// Capabilities the base Oracle REST bridge does not have:
///   1. Curated local sound pack        (bundled assets, no scraping)
///   2. Oracle BLOB file storage       (POST /api/files/upload, GET /api/files/:id)
///   3. Video -> audio extraction      (POST /api/extract-audio)
///   4. Link -> audio ripper           (POST /api/rip)
///   5. Toothbrush photo detection     (POST /api/detect/toothbrush)
///   6. Node/email delivery            (POST /api/email/send)
///
/// `OracleConfig.apiBaseUrl` already ends in `/api`, so each path below is
/// written relative to it (`$base/extract-audio` == `/api/extract-audio`).
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
import '../utils/sound_catalog.dart';

/// One bounding box from the optional toothbrush detector.
class DetectionBox {
  const DetectionBox({
    required this.className,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory DetectionBox.fromJson(Map<String, dynamic> json) {
    return DetectionBox(
      // The backend key is `class` (a reserved word in Dart).
      className: (json['class'] ?? json['className'] ?? 'unknown').toString(),
      confidence: _asDouble(json['confidence']),
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      width: _asDouble(json['width']),
      height: _asDouble(json['height']),
    );
  }

  /// `class` from the wire payload, exposed under two convenient names.
  final String className;
  String get label => className;

  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;

  @override
  String toString() => '$className@${confidence.toStringAsFixed(2)}';
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

bool _hasValue(Object? value) =>
    value != null && value.toString().trim().isNotEmpty;

/// Render nested backend error payloads (`{error: {message: ...}}`) readable.
String _flatten(Object? value) {
  if (value == null) return '';
  if (value is Map) {
    return value.entries
        .map((MapEntry<Object?, Object?> e) => '${e.key}=${_flatten(e.value)}')
        .join(', ');
  }
  if (value is List) return value.map(_flatten).join(', ');
  return value.toString();
}

class HypeApi {
  static final HypeApi _instance = HypeApi._internal();
  factory HypeApi() => _instance;
  HypeApi._internal();

  static String get base => OracleConfig.apiBaseUrl;

  /// On Flutter Web, audioplayers creates an HTMLAudioElement with
  /// crossOrigin=anonymous, and almost no media host sends CORS headers.
  /// Route every remote http(s) URL through the backend's same-origin proxy.
  /// Other schemes are returned untouched so the caller can reject them with
  /// a clear message. Native keeps the direct URL (works with no backend).
  static String playableUrl(String url) {
    if (!kIsWeb) return url;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return url;
    final String scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return url;
    return '$base/sounds/proxy?url=${Uri.encodeComponent(url)}';
  }

  /// True for schemes that cannot be fetched on the web (`file://`, `blob:`,
  /// `data:`, custom app protocols, ...). An empty scheme is a relative path.
  static bool isUnsupportedAudioScheme(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;
    final String scheme = uri.scheme.toLowerCase();
    return scheme.isNotEmpty && scheme != 'http' && scheme != 'https';
  }

  /// Minimal audio sniffer for the web fetch path: returns a readable format
  /// name only when [bytes] begin with a known audio magic signature.
  static String? detectAudioFormat(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return 'MP3 (ID3)';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'MPEG/AAC frame';
    }
    if (bytes.length >= 12 &&
        _ascii(bytes, 0, 4) == 'RIFF' &&
        _ascii(bytes, 8, 4) == 'WAVE') {
      return 'WAV';
    }
    if (bytes.length >= 4 && _ascii(bytes, 0, 4) == 'OggS') return 'OGG';
    if (bytes.length >= 8 && _ascii(bytes, 4, 4) == 'ftyp') return 'MP4/M4A (f4a)';
    if (bytes.length >= 4 && _ascii(bytes, 0, 4) == 'fLaC') return 'FLAC';
    return null;
  }

  /// True when a response body is an HTML/XML error page, not audio.
  static bool looksLikeHtml(List<int> bytes) {
    final String head = String.fromCharCodes(bytes.take(256)).toLowerCase();
    return head.contains('<!doctype') ||
        head.contains('<html') ||
        head.contains('<head') ||
        head.contains('<?xml');
  }

  static String _ascii(List<int> bytes, int offset, int length) =>
      String.fromCharCodes(bytes.skip(offset).take(length));

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

  /// Return the small curated sound pack bundled with the app.
  /// No website scraping: these are local assets committed to the project.
  Future<List<Sound>> fetchSounds({String query = '', int limit = 50}) async {
    final String q = query.trim().toLowerCase();
    return defaultSoundOptions
        .where(
          (SoundOption option) =>
              q.isEmpty || option.name.toLowerCase().contains(q),
        )
        .take(limit)
        .map(
          (SoundOption option) => Sound(
            id: option.name,
            name: option.name,
            url: option.url,
            category: 'Bundled',
            imageUrl: '',
          ),
        )
        .toList();
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

  /// Send a recorded video to `POST /api/extract-audio` (multipart `file`,
  /// `kind=video`) and return the Oracle-hosted audio URL from `data['url']`.
  Future<String?> uploadVideoAndExtract(
    File video, {
    String userId = 'demo',
  }) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/extract-audio'),
      );
      request.fields['userId'] = userId;
      request.fields['kind'] = 'video';
      request.files.add(await http.MultipartFile.fromPath('file', video.path));
      final http.StreamedResponse streamed =
          await request.send().timeout(_timeout);
      final http.Response response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Object? decoded = jsonDecode(response.body);
        final String? url = decoded is Map<String, dynamic>
            ? decoded['url'] as String?
            : null;
        if (_hasValue(url)) return url;
        debugPrint('HypeApi: extract-audio returned no url: ${response.body}');
      } else {
        debugPrint(
          'HypeApi: extract-audio HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('HypeApi: extract-audio failed: $e');
    }
    return null;
  }

  /// Paste a TikTok / Reels / YouTube / direct-media URL and get back an
  /// Oracle-hosted audio URL. Returns null on failure, but always prints the
  /// backend's error message instead of swallowing it. Use [ripAudioDetailed]
  /// when the UI needs to explain *why* a rip failed.
  Future<String?> ripAudio(String url, {String userId = 'demo'}) async {
    final Map<String, dynamic>? data =
        await ripAudioDetailed(url, userId: userId);
    if (data == null) {
      debugPrint('HypeApi: ripAudio($url) got no response from backend');
      return null;
    }
    final String? audioUrl = data['url'] as String?;
    if (_hasValue(audioUrl)) return audioUrl;
    debugPrint('HypeApi: ripAudio($url) failed: ${_ripError(data)}');
    return null;
  }

  /// Full backend response for a rip request, including any error details.
  /// Never throws: transport problems come back as `{'error': '...'}` so the
  /// UI can show them. Success payloads are returned unchanged.
  Future<Map<String, dynamic>?> ripAudioDetailed(
    String url, {
    String userId = 'demo',
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse('$base/rip'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url, 'userId': userId}),
          )
          .timeout(_timeout);
      final bool ok = response.statusCode == 200 || response.statusCode == 201;
      Map<String, dynamic> data;
      try {
        final Object? decoded = jsonDecode(response.body);
        data = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'raw': response.body};
      } catch (_) {
        data = <String, dynamic>{'raw': response.body};
      }
      if (!ok && !_hasValue(data['error']) && !_hasValue(data['message'])) {
        final String message =
            'HTTP ${response.statusCode}: ${_flatten(data['raw'] ?? response.body)}';
        data = Map<String, dynamic>.from(data)..putIfAbsent('error', () => message);
      }
      if (ok && !_hasValue(data['url']) && !_hasValue(data['error'])) {
        data = Map<String, dynamic>.from(data)
          ..putIfAbsent('error', () => 'Backend returned no audio URL');
      }
      return data;
    } catch (e) {
      debugPrint('HypeApi: rip request failed: $e');
      return <String, dynamic>{'error': 'Network error: $e'};
    }
  }

  static String _ripError(Map<String, dynamic> data) {
    final List<String> parts = <String>[];
    for (final String key in <String>[
      'error',
      'message',
      'detail',
      'details',
      'raw',
    ]) {
      final Object? value = data[key];
      if (_hasValue(value)) parts.add(_flatten(value));
    }
    return parts.isEmpty ? 'unknown backend error' : parts.join(' | ');
  }

  /// Run the optional toothbrush detector on a proof photo.
  ///
  /// Returns a map with `success`, `configured`, `detections` (parsed
  /// [DetectionBox] objects), `raw` backend JSON and possibly `error`.
  /// `null` means the backend could not be reached at all. `configured:false`
  /// means the server is reachable but has no detector model installed, so
  /// callers can keep their deterministic checks in that case.
  Future<Map<String, dynamic>?> detectToothbrush(File photo) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/detect/toothbrush'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));
      final http.StreamedResponse streamed =
          await request.send().timeout(_timeout);
      final http.Response response = await http.Response.fromStream(streamed);
      final bool ok = response.statusCode == 200 || response.statusCode == 201;

      Map<String, dynamic> data;
      try {
        final Object? decoded = jsonDecode(response.body);
        data = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'raw': response.body};
      } catch (_) {
        data = <String, dynamic>{'raw': response.body};
      }

      final Object? configuredValue = data['configured'];
      final bool configured = configuredValue is bool
          ? configuredValue
          : ok && configuredValue == null;
      final dynamic rawDetections = data['detections'];
      final List<DetectionBox> boxes = rawDetections is List
          ? rawDetections
              .whereType<Map>()
              .map(
                (dynamic e) =>
                    DetectionBox.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : <DetectionBox>[];

      if (!ok && !_hasValue(data['error'])) {
        final String message =
            'HTTP ${response.statusCode}: ${_flatten(data['raw'] ?? response.body)}';
        data = Map<String, dynamic>.from(data)
          ..putIfAbsent('error', () => message);
      }
      return <String, dynamic>{
        'success': data['success'] == true || data['success'] == 'true',
        'configured': configured,
        'detections': boxes,
        'raw': data,
      };
    } catch (e) {
      debugPrint('HypeApi: toothbrush detection failed: $e');
      return null;
    }
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
