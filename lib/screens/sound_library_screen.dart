/// Sound library screen - browse and manage custom sounds.
library;
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/sound_service.dart';

class SoundLibraryScreen extends StatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  State<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends State<SoundLibraryScreen> {
  List<Sound> _sounds = [];
  bool _isLoading = true;
  String _selectedCategory = 'Alarm';

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  Future<void> _loadSounds() async {
    final sounds = await SoundManager().fetchSounds(category: _selectedCategory, limit: 50);
    setState(() {
      _sounds = sounds;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSounds,
            tooltip: 'Refresh Sounds',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSoundList(),
    );
  }

  Widget _buildSoundList() {
    if (_sounds.isEmpty) {
      return const Center(
        child: Text(
          'No sounds available. Try refreshing.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
      );
    }

    return Column(
      children: [
        // Category filter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.yellow.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Text(
                'Filter: ',
                style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
              ),
              ...SoundManager().getCategories().map((category) => FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                selectedColor: Colors.yellow,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                    _loadSounds();
                  });
                },
              )),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _sounds.length,
            itemBuilder: (context, index) {
              final sound = _sounds[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.yellow,
                    ),
                  ),
                  title: Text(
                    sound.name,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  subtitle: Text(
                    sound.category,
                    style: const TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                  trailing: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  onTap: () {
                    // Play the sound
                    _playSound(sound.url);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _playSound(String url) async {
    // Import audio service to play sound
    final audioService = AudioService();
    try {
      await audioService.play(url);
    } catch (e) {
      debugPrint('Failed to play sound: $e');
    }
  }
}

// Need to import audio service at the top
