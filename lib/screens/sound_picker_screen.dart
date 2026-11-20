/// One place to browse and choose an alarm sound.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/custom_sound_service.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:hypemotiv/services/sound_service.dart';
import 'package:hypemotiv/utils/sound_catalog.dart';

class SoundPickerScreen extends StatefulWidget {
  const SoundPickerScreen({super.key});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen> {
  final TextEditingController _search = TextEditingController();
  List<SoundOption> _options = List<SoundOption>.from(defaultSoundOptions);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<CustomSound> custom = await CustomSoundService().list();
    final List<Sound> remote = await HypeApi().fetchSounds(limit: 40);
    if (!mounted) return;
    setState(() {
      _options = <SoundOption>[
        ...custom.map(
          (CustomSound sound) => SoundOption(name: sound.name, url: sound.path),
        ),
        ...defaultSoundOptions,
        ...remote.map(
          (Sound sound) => SoundOption(name: sound.name, url: sound.url),
        ),
      ];
      _loading = false;
    });
  }

  Future<void> _addCustom() async {
    final CustomSound? sound = await CustomSoundService().pickAndSave();
    if (!mounted) return;
    if (sound != null) {
      await AudioService().play(sound.path);
      await _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _search.text.trim().toLowerCase();
    final List<SoundOption> visible = _options
        .where((SoundOption option) => option.name.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose alarm sound')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search sounds',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton.icon(
              onPressed: _addCustom,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add sound from this phone'),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (BuildContext context, int index) {
                final SoundOption option = visible[index];
                return ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: Text(option.name, maxLines: 1),
                  subtitle: Text(
                    option.url.startsWith('/') ? 'On this phone' : 'Online sound',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Preview',
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => AudioService().play(option.url),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(option),
                        child: const Text('Use'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
