/// Screen 06 — first-run setup / morning routine enrolment.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/sound_picker_screen.dart';
import 'package:hypemotiv/screens/task_picker_screen.dart';
import 'package:hypemotiv/services/task_selection_service.dart';
import 'package:hypemotiv/utils/task_catalog.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/auth_service.dart';
import 'package:hypemotiv/utils/sound_catalog.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, this.onEnter});

  final VoidCallback? onEnter;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _handleController = TextEditingController(
    text: 'cybersamurail_09',
  );
  final TextEditingController _passcodeController = TextEditingController();
  int _disciplineIndex = 0;
  SoundOption _selectedSound = defaultSoundOptions.first;
  List<String> _selectedTasks = wakeTasks.map((WakeTask task) => task.id).toList();

  static const List<String> _disciplines = <String>[
    'David Goggins',
    'Brutal friend',
    'Bass-boosted music',
  ];

  static const List<IconData> _disciplineIcons = <IconData>[
    Icons.emoji_events,
    Icons.record_voice_over,
    Icons.graphic_eq,
  ];

  @override
  void dispose() {
    _handleController.dispose();
    _passcodeController.dispose();
    super.dispose();
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

  @override
  void initState() {
    super.initState();
    TaskSelectionService().selected().then((List<String> ids) {
      if (mounted) setState(() => _selectedTasks = ids);
    });
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
                    status: 'Morning setup',
                    trailing: 'Step 1 of 1',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Set up your morning routine',
                    style: TextStyle(
                      color: Color(0xFF1F2933),
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose how you want to wake up, then add a photo check-in '
                    'so you start the day on track.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Alarm sound preview
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SectionLabel(
                          'Alarm sound',
                          trailing: _selectedSound.name,
                        ),
                        const SizedBox(height: 8),
                        const Waveform(
                          color: Color(0xFF3D5AFE),
                          bars: 48,
                          height: 52,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Preview sound'),
                          onPressed: () => AudioService().play(_selectedSound.url),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.music_note),
                          label: const Text('Choose from meme sounds'),
                          onPressed: () async {
                            final SoundOption? picked = await Navigator.of(
                              context,
                            ).push<SoundOption>(
                              MaterialPageRoute<SoundOption>(
                                builder: (BuildContext context) =>
                                    const SoundPickerScreen(),
                              ),
                            );
                            if (picked == null || !mounted) return;
                            setState(() => _selectedSound = picked);
                            await AudioService().play(picked.url);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.checklist),
                    label: Text(
                      'Wake-up tasks: ${_selectedTasks.length} selected (change)',
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const TaskPickerScreen(),
                        ),
                      );
                      final List<String> ids =
                          await TaskSelectionService().selected();
                      if (mounted) setState(() => _selectedTasks = ids);
                    },
                  ),
                  const SizedBox(height: 18),

                  const MicroText(
                    'Sign-in options',
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<String?>(
                    future: AuthService().savedUser(),
                    builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                      return CyberCard(
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF12B76A)),
                            const SizedBox(width: 10),
                            Text(
                              'Signed in as ${snapshot.data ?? 'this device'}',
                              style: const TextStyle(
                                color: Color(0xFF1F2933),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  const MicroText(
                    'Name or email',
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _handleController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFF3D5AFE),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const MicroText(
                    'Passcode',
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passcodeController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Color(0xFF3D5AFE),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel(
                    'Choose your alarm style',
                    trailing: 'One choice',
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _disciplines.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _disciplineIndex = i),
                        child: CyberCard(
                          glow: _disciplineIndex == i,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                _disciplineIcons[i],
                                color: _disciplineIndex == i
                                    ? CyberTheme.lime
                                    : CyberTheme.muted,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MicroText(
                                  _disciplines[i],
                                  color: _disciplineIndex == i
                                      ? CyberTheme.lime
                                      : CyberTheme.white,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(
                                _disciplineIndex == i
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _disciplineIndex == i
                                    ? CyberTheme.lime
                                    : CyberTheme.muted,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),

                  const SectionLabel(
                    'Photo check-in',
                    trailing: 'Required',
                  ),
                  const SizedBox(height: 10),
                  const _ProofRow(
                    icon: Icons.water_drop,
                    text: 'Photo of your sink and toothbrush',
                  ),
                  const SizedBox(height: 8),
                  const _ProofRow(
                    icon: Icons.accessibility_new,
                    text: '20 squats on camera',
                  ),
                  const SizedBox(height: 18),

                  const CyberCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        MicroText(
                          '48k morning check-ins',
                          color: Color(0xFF3D5AFE),
                          fontSize: 12,
                          textAlign: TextAlign.center,
                        ),
                        MicroText(
                          'No snoozes',
                          color: Color(0xFF0F766E),
                          fontSize: 12,
                          textAlign: TextAlign.center,
                        ),
                        MicroText(
                          'Sync your devices',
                          color: Color(0xFF667085),
                          fontSize: 12,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'Finish setup',
                    icon: Icons.check,
                    onPressed: widget.onEnter,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => _toast('Privacy'),
                        child: const MicroText(
                          'Privacy',
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _toast('Snooze policy'),
                        child: const MicroText(
                          'Snooze policy',
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _toast('Support'),
                        child: const MicroText(
                          'Support',
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, color: CyberTheme.cyan, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: MicroText(text, color: CyberTheme.white, fontSize: 13),
          ),
          const StatusChip('On'),
        ],
      ),
    );
  }
}
