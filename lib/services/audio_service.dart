/// Audio playback for alarm sounds, ripped clips and voice messages.
///
/// Falls back to a verified, publicly reachable sound when a URL is empty or
/// fails, so the alarm always makes a noise even with no backend connection.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hypemotiv/services/hype_api.dart';

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
      await _audioPlayer.setSourceUrl(playable);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('AudioService: could not play $source ($e); using fallback');
      await _playFallback();
    }
  }

  Future<void> _playFallback() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(HypeApi.playableUrl(fallbackSoundUrl));
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
