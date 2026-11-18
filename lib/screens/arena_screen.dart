/// Screen 02 — active prime / dawn raid sprint command centre.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:hypemotiv/services/sound_service.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

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
  });

  final String time;
  final String title;
  final String subtitle;
  final bool enabled;

  _Protocol copyWith({bool? enabled}) {
    return _Protocol(
      time: time,
      title: title,
      subtitle: subtitle,
      enabled: enabled ?? this.enabled,
    );
  }
}

class _ArenaScreenState extends State<ArenaScreen> {
  static const String _fallbackSoundUrl =
      'https://www.soundjay.com/alarms/sounds/bell-1.mp3';

  final List<_Protocol> _protocols = <_Protocol>[
    const _Protocol(
      time: '05:45 AM',
      title: 'Cardio Drill',
      subtitle: 'Hyper Iron Pumping',
    ),
    const _Protocol(
      time: '07:15 AM',
      title: 'Deep Focus',
      subtitle: 'Code Sprint Ignition',
    ),
  ];

  String _drillUrl = _fallbackSoundUrl;
  bool _audioLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDrill();
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
        content: Text('AUDIO DRILL STREAMING // WAR VOLUME'),
        backgroundColor: Color(0xFF111A15),
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
                    status: 'ACTIVE PRIME',
                    trailing: '12m to sleep',
                  ),
                  const SizedBox(height: 24),
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'DAWN RAID SPRINT',
                          trailing: 'PRIME // 01',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '06:30 AM',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFFB6FF3B),
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            shadows: <Shadow>[
                              Shadow(
                                color: Color(0x55B6FF3B),
                                blurRadius: 18,
                              ),
                            ],
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
                                  fontFamily: 'monospace',
                                  color: Color(0xFFF4F8F3),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const StatusChip('LIVE'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Waveform(
                          color: Color(0xFF00E5FF),
                          bars: 36,
                          height: 44,
                        ),
                        const SizedBox(height: 10),
                        NeonButton(
                          label: _audioLoading ? 'LOADING DRILL...' : 'AUDIO DRILL',
                          icon: Icons.play_arrow,
                          onPressed: _playDrill,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: NeonButton(
                                label: 'Proof: Bathroom Shrink',
                                primary: false,
                                icon: Icons.photo_camera,
                                height: 46,
                                fontSize: 10,
                                onPressed: () => _toast(
                                  'PROOF CAPTURE QUEUED // BATHROOM SHRINK',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        NeonButton(
                          label: 'NO SNOOZE ALLOWED',
                          primary: false,
                          icon: Icons.lock,
                          height: 44,
                          fontSize: 11,
                          onPressed: () => _toast('SNOOZE PORT SEALED'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('DISCIPLINE BENTO', trailing: 'LIVE STATS'),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _BentoCard(
                          value: '14 DAYS',
                          caption: '+3 vs last month',
                          color: CyberTheme.lime,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BentoCard(
                          value: '0 SNOOZES',
                          caption: 'Pure Discipline',
                          color: CyberTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BentoCard(
                    value: 'DOPAMINE SHIELD',
                    caption: 'BLOCKED',
                    color: CyberTheme.danger,
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel(
                    'SCHEDULED PROTOCOLS',
                    trailing: 'AUTO-ARMED',
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
                                  fontSize: 11,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  protocol.title,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFFF4F8F3),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                MicroText(
                                  protocol.subtitle,
                                  color: CyberTheme.muted,
                                  fontSize: 9,
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
                    label: '+ CREATE NEW PROTOCOL',
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
        backgroundColor: CyberTheme.panelAlt,
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
          MicroText(value, color: color, fontSize: 15, letterSpacing: 1),
          const SizedBox(height: 6),
          MicroText(
            caption,
            color: CyberTheme.muted,
            fontSize: 9,
            letterSpacing: 0.8,
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
    text: 'New Drill',
  );
  final TextEditingController _subtitleController = TextEditingController(
    text: 'Iron Discipline Protocol',
  );

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
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1E2A22)),
      ),
      title: const MicroText(
        'NEW PROTOCOL',
        color: Color(0xFFB6FF3B),
        fontSize: 13,
        letterSpacing: 2,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _timeController,
            decoration: const InputDecoration(labelText: 'TIME (HH:MM AM)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'PROTOCOL NAME'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(labelText: 'DRILL DETAIL'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const MicroText('CANCEL', color: Color(0xFF7C8C82)),
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
              ),
            );
          },
          child: const MicroText('ARM PROTOCOL', color: Color(0xFFB6FF3B)),
        ),
      ],
    );
  }
}
