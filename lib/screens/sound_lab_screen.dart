/// Screen 03 — sound library, audio extraction and recordings.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/custom_sound_service.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:hypemotiv/services/sound_service.dart';
import 'package:hypemotiv/services/tts_service.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kSavedAlarmKey = 'hype_saved_alarm_sound';

final List<Sound> _featuredSounds = <Sound>[
  Sound(
    id: 'bruh_2',
    name: 'Bruh Sound #2',
    url: 'https://www.myinstants.com/media/sounds/bruh-sound-2.mp3',
    category: 'Meme',
    imageUrl: '',
  ),
  Sound(
    id: 'roblox_oof',
    name: 'Roblox OOF',
    url: 'https://www.myinstants.com/media/sounds/roblox-oof.mp3',
    category: 'Meme',
    imageUrl: '',
  ),
  Sound(
    id: 'airhorn_stadium',
    name: 'Airhorn Stadium',
    url: 'https://www.myinstants.com/media/sounds/airhorn-stadium.mp3',
    category: 'Alarm',
    imageUrl: '',
  ),
  Sound(
    id: 'emotional_damage',
    name: 'Emotional Damage!',
    url: 'https://www.myinstants.com/media/sounds/emotional-damage.mp3',
    category: 'Meme',
    imageUrl: '',
  ),
  Sound(
    id: 'robert_b_weide',
    name: 'Robert B. Weide',
    url: 'https://www.myinstants.com/media/sounds/robert-b-weide.mp3',
    category: 'Meme',
    imageUrl: '',
  ),
  Sound(
    id: 'fbi_open_up',
    name: 'FBI Open Up',
    url: 'https://www.myinstants.com/media/sounds/fbi-open-up.mp3',
    category: 'Meme',
    imageUrl: '',
  ),
];

class SoundLabScreen extends StatefulWidget {
  const SoundLabScreen({super.key});

  @override
  State<SoundLabScreen> createState() => _SoundLabScreenState();
}

class _SoundLabScreenState extends State<SoundLabScreen> {
  static const String _fallbackSoundUrl =
      'https://www.myinstants.com/media/sounds/bruh-sound-effect_WstdzdM.mp3';
  static const String _demoRipUrl =
      'https://media.hypemotiv.app/rips/dawn-roast-060.mp3';

  final TextEditingController _ripController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _roastController = TextEditingController();
  final TTSService _tts = TTSService();
  String _voiceCharacter = 'Calm';

  List<Sound> _sounds = _featuredSounds;
  List<CustomSound> _customSounds = const <CustomSound>[];
  String? _ripUrl;
  bool _ripBusy = false;
  bool _searching = false;
  bool _recording = false;
  bool _uploadBusy = false;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_tts.init());
    unawaited(_loadSounds(''));
    unawaited(_loadCustom());
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _ripController.dispose();
    _searchController.dispose();
    _roastController.dispose();
    unawaited(_tts.dispose());
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CyberTheme.panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadCustom() async {
    final List<CustomSound> sounds = await CustomSoundService().list();
    if (!mounted) return;
    setState(() => _customSounds = sounds);
  }

  Future<void> _addCustom() async {
    final CustomSound? sound = await CustomSoundService().pickAndSave();
    if (!mounted) return;
    if (sound == null) {
      _toast('No audio file selected');
      return;
    }
    await _loadCustom();
    _toast('${sound.name} added');
  }

  Future<void> _loadSounds(String query) async {
    setState(() => _searching = true);
    final List<Sound> fetched = await HypeApi().fetchSounds(query: query);
    if (!mounted) return;
    setState(() {
      _sounds = query.trim().isEmpty
          ? _featuredSounds
          : (fetched.isNotEmpty ? fetched : _featuredSounds);
      _searching = false;
    });
  }

  Future<void> _rip() async {
    final String url = _ripController.text.trim();
    if (url.isEmpty) {
      _toast('Paste a link first');
      return;
    }
    setState(() => _ripBusy = true);
    final String? result = await HypeApi().ripAudio(url);
    if (!mounted) return;
    setState(() {
      _ripUrl = result ?? _demoRipUrl;
      _ripBusy = false;
    });
    _toast(result == null ? 'Demo audio loaded' : 'Audio extracted');
  }

  Future<void> _preview(String? url) async {
    try {
      await AudioService().play(url ?? _fallbackSoundUrl);
    } catch (_) {
      // Audio failures never reach the UI.
    }
    _toast('Playing preview');
  }

  Future<void> _saveToAlarm() async {
    final String url = _ripUrl ?? _fallbackSoundUrl;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedAlarmKey, url);
    _toast('Saved as your alarm sound');
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) {
      _toast('Write a message first');
      return;
    }
    try {
      await _tts.speakWithCharacter(text.trim(), _voiceCharacter);
    } catch (_) {
      // TTS failures never reach the UI.
    }
  }

  void _startRecording() {
    _recordingTimer?.cancel();
    setState(() => _recording = true);
    _recordingTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() => _recording = false);
    });
  }

  Future<void> _endRecording() async {
    _recordingTimer?.cancel();
    if (!mounted) return;
    setState(() => _recording = false);

    // file_picker v12+ returns List<PlatformFile> and uses a static API.
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.audio,
    );
    if (picked.isEmpty || picked.first.path == null || !mounted) {
      _toast('No recording selected');
      return;
    }

    setState(() => _uploadBusy = true);
    final String? url = await HypeApi().uploadFile(
      File(picked.first.path!),
      kind: 'audio',
    );
    if (!mounted) return;
    setState(() => _uploadBusy = false);
    _toast(url == null ? 'Recording saved on device' : 'Recording uploaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BrandHeader(
                    status: 'Sound library',
                    trailing: 'Ready',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sound library',
                    style: TextStyle(
                      color: Color(0xFF1F2933),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Extract audio from a video
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'Extract audio from a video',
                          trailing: 'Optional',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Paste a TikTok, Reels or YouTube link',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ripController,
                          decoration: const InputDecoration(
                            hintText: 'https://tiktok.com/@runner/video/...',
                            prefixIcon: Icon(
                              Icons.link,
                              color: Color(0xFF0F766E),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonButton(
                          label: _ripBusy ? 'Extracting...' : 'Extract audio',
                          icon: Icons.content_cut,
                          onPressed: _rip,
                        ),
                        if (_ripUrl != null) ...<Widget>[
                          const SizedBox(height: 14),
                          CyberCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                MicroText(
                                  _ripUrl!,
                                  color: Color(0xFF0F766E),
                                  fontSize: 12,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                const Waveform(
                                  color: Color(0xFF3D5AFE),
                                  bars: 32,
                                  height: 42,
                                ),
                                const MicroText(
                                  '00:06.20',
                                  color: Color(0xFF667085),
                                  fontSize: 12,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: NeonButton(
                                  label: 'Preview',
                                  icon: Icons.play_arrow,
                                  height: 44,
                                  fontSize: 13,
                                  onPressed: () => _preview(_ripUrl),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: NeonButton(
                                  label: 'Save to alarm',
                                  primary: false,
                                  icon: Icons.alarm_add,
                                  height: 44,
                                  fontSize: 13,
                                  onPressed: _saveToAlarm,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Popular sounds
                  const SectionLabel(
                    'Popular sounds',
                    trailing: 'Browse',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: _loadSounds,
                    decoration: const InputDecoration(
                      hintText: 'Search sounds',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF3D5AFE),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_searching)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: Color(0xFF3D5AFE),
                      backgroundColor: Color(0xFFE4E7EC),
                    ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sounds.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 128,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final Sound sound = _sounds[index];
                      return CyberCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.graphic_eq,
                              color: CyberTheme.cyan,
                              size: 20,
                            ),
                            const Spacer(),
                            Text(
                              sound.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F2933),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _preview(sound.url),
                              child: const MicroText(
                                'Play',
                                color: Color(0xFF3D5AFE),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                unawaited(
                                  _saveSoundToAlarm(sound.url),
                                );
                              },
                              child: const MicroText(
                                'Use as alarm',
                                color: Color(0xFF0F766E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  const SectionLabel(
                    'Your sounds',
                    trailing: 'On this phone',
                  ),
                  const SizedBox(height: 10),
                  NeonButton(
                    label: 'Add custom sound from phone',
                    icon: Icons.add_circle_outline,
                    onPressed: _addCustom,
                  ),
                  if (_customSounds.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    ..._customSounds.map(
                      (CustomSound sound) => CyberCard(
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.audiotrack, color: Color(0xFF3D5AFE)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sound.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Play',
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () => AudioService().play(sound.path),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await CustomSoundService().delete(sound);
                                await _loadCustom();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Voice recordings
                  const SectionLabel(
                    'Voice recordings',
                    trailing: 'Ready',
                  ),
                  const SizedBox(height: 10),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const MicroText(
                          'Record a message',
                          color: Color(0xFF667085),
                          fontSize: 13,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Record a short message to play when your alarm '
                          'goes off.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onLongPress: _startRecording,
                          onLongPressEnd: (LongPressEndDetails details) {
                            unawaited(_endRecording());
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _recording
                                  ? CyberTheme.danger.withValues(alpha: 0.10)
                                  : CyberTheme.lime.withValues(alpha: 0.08),
                              border: Border.all(
                                color: _recording
                                    ? CyberTheme.danger
                                    : CyberTheme.lime,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: MicroText(
                                _uploadBusy
                                    ? 'Uploading'
                                    : _recording
                                        ? 'Recording'
                                        : 'Hold to record',
                                color: _recording
                                    ? CyberTheme.danger
                                    : CyberTheme.lime,
                                fontSize: 12,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _roastController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Write your message...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _voiceCharacter,
                          decoration: const InputDecoration(
                            labelText: 'Voice character',
                          ),
                          items: <DropdownMenuItem<String>>[
                            for (final String name in TTSService.characters)
                              DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() => _voiceCharacter = value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        NeonButton(
                          label: 'Play message',
                          primary: false,
                          icon: Icons.record_voice_over,
                          onPressed: () => _speak(_roastController.text),
                        ),
                        const SizedBox(height: 16),
                        const MicroText(
                          'Suggested messages',
                          color: Color(0xFF667085),
                          fontSize: 13,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: NeonButton(
                                label: 'Firm reminder',
                                primary: false,
                                height: 44,
                                fontSize: 12,
                                onPressed: () => _speak(
                                  'Drop and give me twenty! Sleep is for the weak!',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: NeonButton(
                                label: 'Friendly nudge',
                                primary: false,
                                height: 44,
                                fontSize: 12,
                                onPressed: () => _speak(
                                  'Oh look, you overslept again. Groundbreaking.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const ScanOverlay(),
        ],
      ),
    );
  }

  Future<void> _saveSoundToAlarm(String url) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedAlarmKey, url);
    _toast('Saved as your alarm sound');
  }
}
