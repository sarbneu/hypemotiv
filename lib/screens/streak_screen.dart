library;
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/streak_service.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final StreakService _streakService = StreakService();
  bool _isLoading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _currentStreak = _streakService.currentStreak;
        _longestStreak = _streakService.longestStreak;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Streak'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStreakCard(),
                  const SizedBox(height: 24),
                  _buildStreakHistory(),
                  const SizedBox(height: 24),
                  const Text(
                    'Challenges',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _buildChallengeList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      color: Colors.yellow.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '🔥',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '$_currentStreak',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'day streak',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Longest: $_longestStreak days',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHistory() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildStreakRow('Today', '10:30 AM', Colors.yellow),
            const SizedBox(height: 4),
            _buildStreakRow('Yesterday', '9:45 AM', Colors.grey),
            const SizedBox(height: 4),
            _buildStreakRow('Day 3', '8:20 AM', Colors.grey),
            const SizedBox(height: 4),
            _buildStreakRow('Day 4', '9:15 AM', Colors.grey),
            const SizedBox(height: 4),
            _buildStreakRow('Day 5', '10:00 AM', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakRow(String label, String time, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
        Text(time, style: const TextStyle(color: Color(0xFFB0B0B0))),
      ],
    );
  }

  Widget _buildChallengeList() {
    final challenges = const [
      {'title': 'Complete 5 tasks today', 'emoji': '✅', 'points': 100},
      {'title': 'Sleep 7+ hours', 'emoji': '😴', 'points': 200},
      {'title': 'No snooze alarm', 'emoji': '🚫', 'points': 150},
      {'title': 'Meditation 10 mins', 'emoji': '🧘', 'points': 100},
      {'title': 'Exercise 30 mins', 'emoji': '🏃', 'points': 300},
    ];

    return Column(
      children: challenges.map((c) {
        return Card(
          color: const Color(0xFF1E1E1E),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.yellow.withValues(alpha: 0.2),
              child: Text(c['emoji'] as String? ?? '', style: const TextStyle(fontSize: 18)),
            ),
            title: Text(c['title'] as String? ?? '', style: const TextStyle(color: Colors.white)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${c['points']} pts',
                  style: const TextStyle(color: Colors.green, fontSize: 16),
                ),
                const Text('Next: +50', style: TextStyle(color: Color(0xFFB0B0B0))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
