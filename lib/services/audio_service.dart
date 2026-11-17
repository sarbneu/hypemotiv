/// Audio playback service for playing meme alarm sounds and audio clips.
import 'package:speakers/speakers.dart';
import 'package:audio_session/audio_session.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  Speakers? _speakers;
  Duration? _duration;
  Duration? _position;

  /// Initialize the audio player.
  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.setPlaybackCollisionBehavior(AudioSessionPlaybackCollisionBehavior.Sox);
    await session.setCategory(AudioSessionCategory.playback);

    _speakers = Speakers();
  }

  /// Play a sound file from a local path or URL.
  Future<void> play(String audioUrl, {bool loop = false}) async {
    if (_speakers == null) {
      await init();
    }

    await _speakers!.setSource(
      Source.uri(Uri.parse(audioUrl)),
      isLooping: loop,
    );
    await _speakers!.play();
  }

  /// Pause playback.
  Future<void> pause() async {
    await _speakers!.pause();
  }

  /// Resume playback.
  Future<void> resume() async {
    await _speakers!.play();
  }

  /// Stop playback and reset position to start.
  Future<void> stop() async {
    await _speakers!.stop();
    _position = Duration.zero;
  }

  /// Get the current playback position.
  Duration? get currentPosition => _position;

  /// Get the total duration of the current audio.
  Duration? get duration => _duration;

  /// Check if currently playing.
  bool get isPlaying => _speakers?.isPlaying ?? false;

  /// Get the playback state.
  SpeakersState get state => _speakers?.state ?? SpeakersState.stopped;

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }
}
