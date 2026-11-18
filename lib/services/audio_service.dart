/// Audio playback service for playing meme alarm sounds and audio clips.
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  late AudioPlayer _audioPlayer;
  Duration? _position;

  /// Initialize the audio player.
  Future<void> init() async {
    _audioPlayer = AudioPlayer();
  }

  /// Play a sound file from a local path or URL.
  Future<void> play(String audioUrl, {bool loop = false}) async {
    await _audioPlayer.setSourceUrl(audioUrl);
    await _audioPlayer.resume();
  }

  /// Pause playback.
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Resume playback.
  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  /// Stop playback.
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Get the total duration of the current audio.
  Future<Duration?> getDuration() async {
    return _audioPlayer.getDuration();
  }

  /// Check if currently playing.
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  /// Get the playback state.
  PlayerState get state => _audioPlayer.state;

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }
}
