library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:http/http.dart' as http;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const String localTestSound = 'assets/audio/test_alarm.wav';

  Future<void> playLocalTest({bool loop = false}) async {
    try {
      await _applyLoop(loop);
      await _audioPlayer.setSourceAsset(localTestSound);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('AudioService: local test sound failed: $e');
      await play(fallbackSoundUrl, loop: loop);
    }
  }

  static const String fallbackSoundUrl = 'assets/audio/bruh.mp3';

  static const Duration _fetchTimeout = Duration(seconds: 15);

  late AudioPlayer _audioPlayer;
  bool _loop = false;
  final Map<String, Uint8List> _bytesCache = <String, Uint8List>{};

  Future<void> init() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const <AVAudioSessionOptions>{},
          ),
        ),
      );
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
    } catch (_) {
    }
  }

  Future<void> play(String audioUrl, {bool loop = false}) async {
    final String source =
        audioUrl.trim().isEmpty ? fallbackSoundUrl : audioUrl.trim();
    try {
      if (kIsWeb && HypeApi.isUnsupportedAudioScheme(source)) {
        throw StateError(
          'Unsupported audio scheme in "$source" '
          '(only http/https URLs can be played on web)',
        );
      }
      final String playable = HypeApi.playableUrl(source);
      await _applyLoop(loop);
      if (source.startsWith('assets/')) {
        await _audioPlayer.setSourceAsset(source);
      } else if (kIsWeb) {
        final Uint8List bytes = await _bytesFor(playable);
        await _audioPlayer.setSourceBytes(bytes);
      } else if (source.startsWith('/')) {
        await _audioPlayer.setSourceDeviceFile(source);
      } else {
        await _audioPlayer.setSourceUrl(playable);
      }
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('AudioService: could not play $source ($e); using fallback');
      await _playFallback();
    }
  }

  Future<void> _applyLoop(bool loop) async {
    if (_loop == loop) return;
    await _audioPlayer.setReleaseMode(
      loop ? ReleaseMode.loop : ReleaseMode.release,
    );
    _loop = loop;
  }

  Future<Uint8List> _bytesFor(String url) async {
    final Uint8List? cached = _bytesCache[url];
    if (cached != null) return cached;
    final http.Response response =
        await http.get(Uri.parse(url)).timeout(_fetchTimeout);
    if (response.statusCode != 200) {
      throw StateError('Audio HTTP ${response.statusCode} from $url');
    }
    final Uint8List bytes = response.bodyBytes;
    if (bytes.isEmpty) throw StateError('Empty audio response from $url');
    final String? format = HypeApi.detectAudioFormat(bytes);
    if (format == null) {
      final String kind = HypeApi.looksLikeHtml(bytes)
          ? 'HTML/error page'
          : 'unrecognised bytes';
      throw StateError('Response from $url is not audio ($kind)');
    }
    if (_bytesCache.length >= 12) _bytesCache.remove(_bytesCache.keys.first);
    _bytesCache[url] = bytes;
    return bytes;
  }

  Future<void> _playFallback() async {
    try {
      final String url = HypeApi.playableUrl(fallbackSoundUrl);
      if (url.startsWith('assets/')) {
        await _audioPlayer.setSourceAsset(url);
      } else if (kIsWeb) {
        await _audioPlayer.setSourceBytes(await _bytesFor(url));
      } else {
        await _audioPlayer.setSourceUrl(url);
      }
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('AudioService: fallback also failed: $e');
    }
  }

  Future<void> pause() => _audioPlayer.pause();
  Future<void> resume() => _audioPlayer.resume();
  Future<void> stop() => _audioPlayer.stop();
  Future<Duration?> getDuration() => _audioPlayer.getDuration();

  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  PlayerState get state => _audioPlayer.state;

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> dispose() => _audioPlayer.dispose();
}
