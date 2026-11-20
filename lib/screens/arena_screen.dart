/// Screen 02 — morning alarm dashboard.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/custom_sound_service.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:hypemotiv/services/notification_service.dart';
import 'package:hypemotiv/services/proof_service.dart';
import 'package:hypemotiv/services/sound_service.dart';
import 'package:hypemotiv/services/tts_service.dart';
import 'package:hypemotiv/screens/sound_picker_screen.dart';
import 'package:hypemotiv/utils/sound_catalog.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

const List<Map<String, String>> kAlarmSounds = <Map<String, String>>[
  {'name': 'Bruh', 'url': 'https://www.myinstants.com/media/sounds/bruh-sound-effect_WstdzdM.mp3'},
  {'name': 'Airhorn', 'url': 'https://www.myinstants.com/media/sounds/airhorn.mp3'},
  {'name': 'Roblox OOF', 'url': 'https://www.myinstants.com/media/sounds/roblox-oof.mp3'},
  {'name': 'Emotional Damage', 'url': 'https://www.myinstants.com/media/sounds/emotional-damage.mp3'},
  {'name': 'FBI Open Up', 'url': 'https://www.myinstants.com/media/sounds/fbi-open-up.mp3'},
  {'name': 'Bell', 'url': 'https://www.myinstants.com/media/sounds/bell.mp3'},
];

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _Protocol {
  const _Protocol({
    required this.time,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.soundName = 'Bruh',
    this.voice = 'Calm',
  });

  final String time;
  final String title;
  final String subtitle;
  final bool enabled;
  final String soundName;
  final String voice;

  _Protocol copyWith({bool? enabled}) {
    return _Protocol(
      time: time,
      title: title,
      subtitle: subtitle,
      enabled: enabled ?? this.enabled,
      soundName: soundName,
      voice: voice,
    );
  }
}

class _ArenaScreenState extends State<ArenaScreen> {
  static const String _fallbackSoundUrl =
      'https://www.myinstants.com/media/sounds/bruh-sound-effect_WstdzdM.mp3';

  final List<_Protocol> _protocols = <_Protocol>[
    const _Protocol(
      time: '05:45 AM',
      title: 'Morning workout',
      subtitle: 'Cardio and strength',
    ),
    const _Protocol(
      time: '07:15 AM',
      title: 'Focus time',
      subtitle: 'Study session',
    ),
  ];

  String _drillUrl = _fallbackSoundUrl;
  bool _audioLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDrill();
    _loadSavedAlarms();
  }

  static const String _alarmsKey = 'hypemotiv_alarms';

  Future<void> _loadSavedAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_alarmsKey) ?? const <String>[];
    final List<_Protocol> restored = stored
        .map((String line) => line.split('|'))
        .where((List<String> parts) => parts.length >= 3)
        .map(
          (List<String> parts) => _Protocol(
            time: parts[0],
            title: parts[1],
            subtitle: parts[2],
            soundName: parts.length > 3 ? parts[3] : 'Bruh',
            voice: parts.length > 4 ? parts[4] : 'Calm',
          ),
        )
        .toList();
    if (!mounted || restored.isEmpty) return;
    setState(() => _protocols.addAll(restored));
  }

  Future<void> _loadDrill() async {
    final List<Sound> sounds = await HypeApi().fetchSounds();
    final String? url = sounds
        .cast<Sound?>()
        .firstWhere(
          (Sound? sound) => sound != null && sound.url.isNotEmpty,
          orElse: () => null,
        )
        ?.url;
    if (!mounted) return;
    setState(() => _drillUrl = url ?? _fallbackSoundUrl);
  }

  Future<void> _playDrill() async {
    setState(() => _audioLoading = true);
    try {
      await AudioService().play(_drillUrl);
    } catch (_) {
      // Audio failures never reach the UI.
    }
    if (!mounted) return;
    setState(() => _audioLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing alarm sound'),
        backgroundColor: Color(0xFFF2F4F7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createProtocol() async {
    final _Protocol? created = await showDialog<_Protocol>(
      context: context,
      builder: (BuildContext dialogContext) => const _ProtocolDialog(),
    );
    if (created == null || !mounted) return;

    setState(() => _protocols.add(created));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> stored =
        List<String>.from(prefs.getStringList(_alarmsKey) ?? const <String>[]);
    stored.add(
      '${created.time}|${created.title}|${created.subtitle}|${created.soundName}|${created.voice}',
    );
    await prefs.setStringList(_alarmsKey, stored);

    final DateTime? scheduled = _parseClock(created.time);
    if (scheduled != null) {
      await NotificationService().scheduleAlarm(
        when: scheduled.isBefore(DateTime.now())
            ? scheduled.add(const Duration(days: 1))
            : scheduled,
        title: created.title,
        body: created.subtitle.isEmpty ? 'Time to wake up' : created.subtitle,
      );
    }

    if (!mounted) return;
    _toast(
      scheduled == null
          ? 'Alarm saved (no valid time, so it was not scheduled)'
          : 'Alarm saved for ${_formatDate(scheduled)}',
    );
  }

  DateTime? _parseClock(String text) {
    final RegExpMatch? match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match == null) return null;
    int hour = int.tryParse(match.group(1) ?? '') ?? -1;
    final int minute = int.tryParse(match.group(2) ?? '') ?? -1;
    final bool pm = (match.group(3) ?? '').toUpperCase() == 'PM';
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;
    if (hour == 12) hour = 0;
    if (pm) hour += 12;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatDate(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _checkIn() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (picked == null || !mounted) {
      _toast('No photo taken');
      return;
    }
    setState(() => _audioLoading = true);
    final String? url = await HypeApi().uploadFile(
      File(picked.path),
      kind: 'proof',
    );
    if (url == null) {
      await ProofService.saveLocally(picked);
    }
    if (!mounted) return;
    setState(() => _audioLoading = false);
    _toast(url == null ? 'Check-in saved on device' : 'Check-in uploaded');
  }

  void _showSnoozePolicy() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Snooze policy'),
        content: const Text(
          'Snoozing is off by default. To take five more minutes, complete 20 jumping jacks from the alarm screen first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
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
                    status: 'Good morning',
                    trailing: '12m to sleep',
                  ),
                  const SizedBox(height: 24),
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'Morning alarm',
                          trailing: 'Up next',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '06:30 AM',
                          style: TextStyle(
                            color: Color(0xFF3D5AFE),
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            const Expanded(
                              child: Text(
                                "David Goggins: Who's Gonna Carr...",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF1F2933),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const StatusChip('On'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Waveform(
                          color: Color(0xFF3D5AFE),
                          bars: 36,
                          height: 44,
                        ),
                        const SizedBox(height: 10),
                        NeonButton(
                          label:
                              _audioLoading ? 'Loading...' : 'Play alarm sound',
                          icon: Icons.play_arrow,
                          onPressed: _playDrill,
                        ),
                        const SizedBox(height: 8),
                        NeonButton(
                          label: 'Play test sound (offline)',
                          icon: Icons.volume_up,
                          primary: false,
                          onPressed: () => AudioService().playLocalTest(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: NeonButton(
                                label: 'Photo check-in',
                                primary: false,
                                icon: Icons.photo_camera,
                                height: 46,
                                fontSize: 13,
                                onPressed: _checkIn,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        NeonButton(
                          label: 'Snooze locked',
                          primary: false,
                          icon: Icons.lock,
                          height: 44,
                          fontSize: 13,
                          onPressed: _showSnoozePolicy,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Today at a glance', trailing: 'Today'),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _BentoCard(
                          value: '14-day streak',
                          caption: '+3 vs last month',
                          color: CyberTheme.lime,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BentoCard(
                          value: 'No snoozes',
                          caption: 'Keep it up',
                          color: CyberTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BentoCard(
                    value: 'Distraction blocking: on',
                    caption: 'Focus mode is active',
                    color: const Color(0xFF12B76A),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel(
                    'Scheduled alarms',
                    trailing: 'Enabled',
                  ),
                  const SizedBox(height: 12),
                  for (final _Protocol protocol in _protocols)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CyberCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                MicroText(
                                  protocol.time,
                                  color: CyberTheme.lime,
                                  fontSize: 13,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  protocol.title,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2933),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                MicroText(
                                  protocol.subtitle,
                                  color: CyberTheme.muted,
                                  fontSize: 12,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Switch(
                              value: protocol.enabled,
                              activeThumbColor: CyberTheme.lime,
                              activeTrackColor: CyberTheme.lime.withValues(
                                alpha: 0.3,
                              ),
                              inactiveThumbColor: CyberTheme.muted,
                              inactiveTrackColor: CyberTheme.line,
                              onChanged: (bool value) {
                                final int index = _protocols.indexOf(protocol);
                                if (index < 0) return;
                                setState(() {
                                  _protocols[index] =
                                      protocol.copyWith(enabled: value);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  NeonButton(
                    label: '+ Add alarm',
                    icon: Icons.add,
                    onPressed: _createProtocol,
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CyberTheme.panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.value,
    required this.caption,
    required this.color,
  });

  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MicroText(value, color: color, fontSize: 15),
          const SizedBox(height: 6),
          MicroText(
            caption,
            color: CyberTheme.muted,
            fontSize: 12,
          ),
        ],
      ),
    );
  }
}

class _ProtocolDialog extends StatefulWidget {
  const _ProtocolDialog();

  @override
  State<_ProtocolDialog> createState() => _ProtocolDialogState();
}

class _ProtocolDialogState extends State<_ProtocolDialog> {
  final TextEditingController _timeController = TextEditingController(
    text: '06:00 AM',
  );
  final TextEditingController _titleController = TextEditingController(
    text: 'New alarm',
  );
  final TextEditingController _subtitleController = TextEditingController(
    text: 'Morning routine',
  );
  int _soundIndex = 0;
  int _voiceIndex = 0;
  List<Map<String, String>> _soundOptions =
      List<Map<String, String>>.from(kAlarmSounds);

  @override
  void initState() {
    super.initState();
    _loadCustomOptions();
  }

  Future<void> _loadCustomOptions() async {
    final List<CustomSound> custom = await CustomSoundService().list();
    if (!mounted) return;
    setState(() {
      _soundOptions = <Map<String, String>>[
        ...kAlarmSounds,
        ...custom.map(
          (CustomSound sound) => <String, String>{
            'name': sound.name,
            'url': sound.path,
          },
        ),
      ];
    });
  }

  @override
  void dispose() {
    _timeController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CyberTheme.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: CyberTheme.line),
      ),
      title: const MicroText(
        'Add an alarm',
        color: Color(0xFF1F2933),
        fontSize: 16,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _timeController,
            decoration: const InputDecoration(labelText: 'Time (HH:MM AM)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Alarm name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.music_note),
            label: Text(
              'Alarm sound: ${_soundOptions[_soundIndex]['name'] ?? 'Sound'}',
            ),
            onPressed: () async {
              final SoundOption? picked = await Navigator.of(context).push<SoundOption>(
                MaterialPageRoute<SoundOption>(
                  builder: (BuildContext context) => const SoundPickerScreen(),
                ),
              );
              if (picked == null || !mounted) return;
              int index = _soundOptions.indexWhere(
                (Map<String, String> option) =>
                    option['name'] == picked.name && option['url'] == picked.url,
              );
              if (index < 0) {
                _soundOptions.add(<String, String>{
                  'name': picked.name,
                  'url': picked.url,
                });
                index = _soundOptions.length - 1;
              }
              setState(() => _soundIndex = index);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Preview selected sound'),
            onPressed: () {
              AudioService().play(
                _soundOptions[_soundIndex]['url'] ?? AudioService.fallbackSoundUrl,
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _voiceIndex,
                  decoration: const InputDecoration(labelText: 'Wake-up voice'),
                  items: <DropdownMenuItem<int>>[
                    for (int i = 0; i < TTSService.characters.length; i++)
                      DropdownMenuItem<int>(
                        value: i,
                        child: Text(TTSService.characters[i]),
                      ),
                  ],
                  onChanged: (int? value) {
                    if (value != null) setState(() => _voiceIndex = value);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Preview voice',
                icon: const Icon(Icons.record_voice_over),
                onPressed: () {
                  TTSService().speakWithCharacter(
                    'Time to wake up',
                    TTSService.characters[_voiceIndex],
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const MicroText('Cancel', color: Color(0xFF667085)),
        ),
        TextButton(
          onPressed: () {
            final String title = _titleController.text.trim();
            if (title.isEmpty) return;
            Navigator.of(context).pop(
              _Protocol(
                time: _timeController.text.trim().isEmpty
                    ? '06:00 AM'
                    : _timeController.text.trim(),
                title: title,
                subtitle: _subtitleController.text.trim(),
                soundName: _soundOptions[_soundIndex]['name'] ?? 'Bruh',
                voice: TTSService.characters[_voiceIndex],
              ),
            );
          },
          child: const MicroText('Save', color: Color(0xFF3D5AFE)),
        ),
      ],
    );
  }
}
