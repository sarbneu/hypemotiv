/// Audio playback for alarm sounds, ripped clips and voice messages.
///
/// Falls back to a verified, publicly reachable sound when a URL is empty or
/// fails, so the alarm always makes a noise even with no backend connection.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:http/http.dart' as http;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  /// Bundled sound: no network, no CORS, no backend needed.
  static const String localTestSound = 'assets/audio/test_alarm.wav';

  /// Play the bundled sound directly. This is the simplest sound check.
  Future<void> playLocalTest({bool loop = false}) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _audioPlayer.setSourceAsset(localTestSound);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('AudioService: local test sound failed: $e');
      await play(fallbackSoundUrl, loop: loop);
    }
  }

  /// Verified reachable meme sound (HTTP 200, audio/mpeg).
  static const String fallbackSoundUrl = 'assets/audio/bruh.mp3';

  static const Duration _fetchTimeout = Duration(seconds: 15);

  late AudioPlayer _audioPlayer;

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
    } catch (_) {
      // Some platforms do not support configuring the audio context.
    }
  }

  /// Play a local file path or a remote URL.
  Future<void> play(String audioUrl, {bool loop = false}) async {
    final String source =
        audioUrl.trim().isEmpty ? fallbackSoundUrl : audioUrl.trim();
    try {
      // On web, only http(s) can be fetched. Reject file://, blob:, data: and
      // custom schemes before http.get produces a confusing "Invalid scheme".
      if (kIsWeb && HypeApi.isUnsupportedAudioScheme(source)) {
        throw StateError(
          'Unsupported audio scheme in "$source" '
          '(only http/https URLs can be played on web)',
        );
      }
      final String playable = HypeApi.playableUrl(source);
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      // On web, audioplayers creates an HTMLAudioElement with
      // crossOrigin=anonymous. Feeding bytes avoids that CORS path entirely.
      // Bundled sounds are real local assets — no scraping, no network, no CORS.
      if (source.startsWith('assets/')) {
        await _audioPlayer.setSourceAsset(source);
      } else if (kIsWeb) {
        final http.Response response =
            await http.get(Uri.parse(playable)).timeout(_fetchTimeout);
        await _setSourceFromResponse(response, playable);
      } else if (source.startsWith('/')) {
        // Custom sounds saved by CustomSoundService on the device.
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

  /// Validate the web response before handing it to audioplayers: an HTML
  /// error page or an empty/HTML body would otherwise be "played" silently.
  /// MIME type is decided by the backend proxy; the client checks magic bytes.
  Future<void> _setSourceFromResponse(
    http.Response response,
    String url,
  ) async {
    if (response.statusCode != 200) {
      throw StateError('Audio HTTP ${response.statusCode} from $url');
    }
    final int length = response.bodyBytes.length;
    if (length == 0) {
      throw StateError('Empty audio response from $url');
    }
    final String? format = HypeApi.detectAudioFormat(response.bodyBytes);
    if (format == null) {
      final String kind = HypeApi.looksLikeHtml(response.bodyBytes)
          ? 'HTML/error page'
          : 'unrecognised bytes';
      throw StateError(
        'Response from $url is not audio ($kind, $length bytes)',
      );
    }
    debugPrint('AudioService: fetched $format audio ($length bytes) from $url');
    await _audioPlayer.setSourceBytes(response.bodyBytes);
  }

  Future<void> _playFallback() async {
    try {
      await _audioPlayer.stop();
      final String url = HypeApi.playableUrl(fallbackSoundUrl);
      if (url.startsWith('assets/')) {
        await _audioPlayer.setSourceAsset(url);
      } else if (kIsWeb) {
        final http.Response response =
            await http.get(Uri.parse(url)).timeout(_fetchTimeout);
        await _setSourceFromResponse(response, url);
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
