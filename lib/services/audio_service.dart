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

  /// Verified reachable meme sound (HTTP 200, audio/mpeg).
  static const String fallbackSoundUrl =
      'https://www.myinstants.com/media/sounds/bruh-sound-effect_WstdzdM.mp3';

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
    final String playable = HypeApi.playableUrl(source);
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      // On web, audioplayers creates an HTMLAudioElement with
      // crossOrigin=anonymous. Feeding bytes avoids that CORS path entirely.
      if (kIsWeb) {
        final http.Response response =
            await http.get(Uri.parse(playable)).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw StateError('Audio HTTP ${response.statusCode}');
        }
        await _audioPlayer.setSourceBytes(response.bodyBytes);
      } else {
        await _audioPlayer.setSourceUrl(playable);
      }
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('AudioService: could not play $source ($e); using fallback');
      await _playFallback();
    }
  }

  Future<void> _playFallback() async {
    try {
      await _audioPlayer.stop();
      final String url = HypeApi.playableUrl(fallbackSoundUrl);
      if (kIsWeb) {
        final http.Response response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        await _audioPlayer.setSourceBytes(response.bodyBytes);
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
