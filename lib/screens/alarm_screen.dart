/// Alarm screen - basic alarm timer with meme audio.
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/sound_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AudioService _audioService = AudioService();
  List<Map<String, dynamic>> _alarms = [
    {
      'title': 'Morning Wake Up',
      'time': '07:00 AM',
      'audioUrl': 'https://www.soundjay.com/alarms/sounds/bell-1.mp3',
      'notes': 'Gentle bell alarm for morning',
      'isCustom': false,
    },
    {
      'title': 'Midday Reminder',
      'time': '12:00 PM',
      'audioUrl': 'https://www.soundjay.com/alarms/sounds/bell-2.mp3',
      'notes': 'Lunch break reminder',
      'isCustom': false,
    },
    {
      'title': 'Evening Wind Down',
      'time': '09:00 PM',
      'audioUrl': 'https://www.soundjay.com/alarms/sounds/bell-3.mp3',
      'notes': 'End of day relaxation alarm',
      'isCustom': false,
    },
  ];
  String _selectedSound = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  Future<void> _loadSounds() async {
    // Try to fetch sounds from myinstants.com
    final sounds = await SoundManager().fetchSounds(category: 'Alarm', limit: 20);
    if (sounds.isNotEmpty) {
      // Use the first sound as default
      _selectedSound = sounds[0].url;
    } else {
      // Fallback to demo sounds
      _selectedSound = 'https://www.soundjay.com/alarms/sounds/bell-1.mp3';
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _playSound(String audioUrl) async {
    try {
      await _audioService.play(audioUrl);
    } catch (e) {
      // Handle play error
      debugPrint('Failed to play sound: $e');
    }
  }

  Future<void> _uploadCustomSound() async {
    // This would open a file picker to upload a custom sound
    // For now, show a dialog to select a sound
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _playSound('https://www.soundjay.com/alarms/sounds/bell-1.mp3');
              },
              icon: const Icon(Icons.alarm),
              label: const Text('Morning Bell 1'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _playSound('https://www.soundjay.com/alarms/sounds/bell-2.mp3');
              },
              icon: const Icon(Icons.alarm),
              label: const Text('Morning Bell 2'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _playSound('https://www.soundjay.com/alarms/sounds/bell-3.mp3');
              },
              icon: const Icon(Icons.alarm),
              label: const Text('Morning Bell 3'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _playSound('https://www.soundjay.com/alarms/sounds/siren-1.mp3');
              },
              icon: const Icon(Icons.warning),
              label: const Text('Siren'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HypeMotiv Alarm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _uploadCustomSound,
            tooltip: 'Add Custom Sound',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAlarmList(),
    );
  }

  Widget _buildAlarmList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alarms.length,
      itemBuilder: (context, index) {
        final alarm = _alarms[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.alarm,
                color: Colors.yellow,
              ),
            ),
            title: Text(
              alarm['title'],
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm['time'],
                  style: const TextStyle(color: Colors.cyan, fontSize: 16),
                ),
                Text(
                  alarm['notes'] ?? '',
                  style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.green,
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
              onPressed: () => _playSound(alarm['audioUrl']),
              tooltip: 'Play alert sound',
            ),
          ),
        );
      },
    );
  }
}
