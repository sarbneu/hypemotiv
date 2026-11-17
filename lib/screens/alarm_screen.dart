/// Alarm screen - basic alarm timer with meme audio.
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/alarm_service.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/utils/oracle_config.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AlarmService _alarmService = AlarmService();
  final AudioService _audioService = AudioService();
  List<Map<String, dynamic>> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _alarms = OracleConfig.suggestedAlarms;
        _isLoading = false;
      });
    }
  }

  Future<void> _playAlarm(String audioUrl) async {
    await _audioService.play(audioUrl, loop: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HypeMotiv Alarm'),
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
                color: Colors.yellow.withValues(0.2),
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
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () => _playAlarm(alarm['audioUrl']),
              tooltip: 'Play alert sound',
            ),
          ),
        );
      },
    );
  }
}
