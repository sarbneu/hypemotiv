library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/oracle_config.dart';
import 'sound_service.dart';
import '../utils/sound_catalog.dart';

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
      className: (json['class'] ?? json['className'] ?? 'unknown').toString(),
      confidence: _asDouble(json['confidence']),
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      width: _asDouble(json['width']),
      height: _asDouble(json['height']),
    );
  }

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

  static String playableUrl(String url) {
    if (!kIsWeb) return url;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return url;
    final String scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return url;
    return '$base/sounds/proxy?url=${Uri.encodeComponent(url)}';
  }

  static bool isUnsupportedAudioScheme(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;
    final String scheme = uri.scheme.toLowerCase();
    return scheme.isNotEmpty && scheme != 'http' && scheme != 'https';
  }

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
    }
    return null;
  }

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

  Future<bool> detectorConfigured() async {
    try {
      final http.Response response =
          await http.get(Uri.parse('$base/detect/status')).timeout(_timeout);
      if (response.statusCode != 200) return false;
      final Object? decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> &&
          decoded['configured'] == true;
    } catch (_) {
      return false;
    }
  }

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
