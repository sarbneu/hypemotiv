/// Screen 03 — audio lab, viral ripper, soundboard and roast vault.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
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
      'https://www.soundjay.com/alarms/sounds/siren-1.mp3';
  static const String _demoRipUrl =
      'https://media.hypemotiv.app/rips/dawn-roast-060.mp3';

  final TextEditingController _ripController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _roastController = TextEditingController();
  final TTSService _tts = TTSService();

  List<Sound> _sounds = _featuredSounds;
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
        backgroundColor: CyberTheme.panelAlt,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      _toast('PASTE A TIKTOK / REELS URL FIRST');
      return;
    }
    setState(() => _ripBusy = true);
    final String? result = await HypeApi().ripAudio(url);
    if (!mounted) return;
    setState(() {
      _ripUrl = result ?? _demoRipUrl;
      _ripBusy = false;
    });
    _toast(result == null ? 'OFFLINE RIP // DEMO DROP LOADED' : 'AUDIO RIP READY');
  }

  Future<void> _preview(String? url) async {
    try {
      await AudioService().play(url ?? _fallbackSoundUrl);
    } catch (_) {
      // Audio failures never reach the UI.
    }
    _toast('PREVIEW DROP // PLAYING');
  }

  Future<void> _saveToAlarm() async {
    final String url = _ripUrl ?? _fallbackSoundUrl;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedAlarmKey, url);
    _toast('SAVED TO ALARM // DISCIPLINE BANK SYNCED');
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) {
      _toast('TYPE A ROAST FIRST');
      return;
    }
    try {
      await _tts.speak(text.trim());
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
      _toast('NO ROAST CAPTURED');
      return;
    }

    setState(() => _uploadBusy = true);
    final String? url = await HypeApi().uploadFile(
      File(picked.first.path!),
      kind: 'audio',
    );
    if (!mounted) return;
    setState(() => _uploadBusy = false);
    _toast(url == null ? 'OFFLINE // ROAST KEPT ON DEVICE' : 'ROAST UPLOADED');
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
                    status: 'AUDIO LAB v2.4',
                    trailing: 'SYS // ONLINE',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SOUND LAB & MEME HUB',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFB6FF3B),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // VIRAL DROP RIPPER
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'VIRAL DROP RIPPER',
                          trailing: 'BETA',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rip TikTok, Reels or brutal accountability roasts',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF7C8C82),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ripController,
                          decoration: const InputDecoration(
                            hintText: 'https://tiktok.com/@runner/video/...',
                            prefixIcon: Icon(
                              Icons.link,
                              color: Color(0xFF00E5FF),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonButton(
                          label: _ripBusy ? 'RIPPING...' : 'RIP AUDIO',
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
                                  color: Color(0xFF00E5FF),
                                  fontSize: 9,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                const Waveform(
                                  color: Color(0xFFB6FF3B),
                                  bars: 32,
                                  height: 42,
                                ),
                                const MicroText(
                                  '00:06.20',
                                  color: Color(0xFF7C8C82),
                                  fontSize: 9,
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
                                  label: 'PREVIEW DROP',
                                  icon: Icons.play_arrow,
                                  height: 44,
                                  fontSize: 10,
                                  onPressed: () => _preview(_ripUrl),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: NeonButton(
                                  label: 'SAVE TO ALARM',
                                  primary: false,
                                  icon: Icons.alarm_add,
                                  height: 44,
                                  fontSize: 10,
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

                  // VIRAL MEME SOUNDBOARD
                  const SectionLabel(
                    'VIRAL MEME SOUNDBOARD',
                    trailing: '100,000+',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: _loadSounds,
                    decoration: const InputDecoration(
                      hintText: 'Search 100,000+ sounds...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFFB6FF3B),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_searching)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: Color(0xFFB6FF3B),
                      backgroundColor: Color(0xFF1E2A22),
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
                                fontFamily: 'monospace',
                                color: Color(0xFFF4F8F3),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _preview(sound.url),
                              child: const MicroText(
                                '▶ TAP TO PLAY',
                                color: Color(0xFF00E5FF),
                                fontSize: 9,
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
                                'SET AS ALARM',
                                color: Color(0xFFB6FF3B),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // VOICE ROAST VAULT
                  const SectionLabel(
                    'VOICE ROAST VAULT',
                    trailing: 'TTS ONLINE',
                  ),
                  const SizedBox(height: 10),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const MicroText(
                          'GYM BUDDY RECORDER',
                          color: Color(0xFF00E5FF),
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Send customized morning wake-up insult to Jake.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF7C8C82),
                            fontSize: 11,
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
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _recording
                                  ? CyberTheme.danger.withValues(alpha: 0.18)
                                  : CyberTheme.lime.withValues(alpha: 0.08),
                              border: Border.all(
                                color: _recording
                                    ? CyberTheme.danger
                                    : CyberTheme.lime,
                                width: 2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: (_recording
                                          ? CyberTheme.danger
                                          : CyberTheme.lime)
                                      .withValues(alpha: 0.24),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Center(
                              child: MicroText(
                                _uploadBusy
                                    ? 'UPLOADING'
                                    : _recording
                                        ? 'RECORDING...'
                                        : 'HOLD',
                                color: _recording
                                    ? CyberTheme.danger
                                    : CyberTheme.lime,
                                fontSize: 11,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _roastController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Write the insult Jake deserves...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonButton(
                          label: 'SPEAK ROAST',
                          primary: false,
                          icon: Icons.record_voice_over,
                          onPressed: () => _speak(_roastController.text),
                        ),
                        const SizedBox(height: 16),
                        const MicroText(
                          'PRE-BUILT ROAST PACKS',
                          color: Color(0xFF7C8C82),
                          fontSize: 9,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: NeonButton(
                                label: 'Drill Sergeant Scream',
                                primary: false,
                                height: 44,
                                fontSize: 9,
                                onPressed: () => _speak(
                                  'Drop and give me twenty! Sleep is for the weak!',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: NeonButton(
                                label: 'Sarcastic Best Friend',
                                primary: false,
                                height: 44,
                                fontSize: 9,
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
    _toast('SET AS ALARM // ROAST BANK UPDATED');
  }
}
