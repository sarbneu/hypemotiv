/// Sleep analytics screen - circadian rhythm analysis.
library;
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/sleep_tracking_service.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final SleepTrackingService _sleepService = SleepTrackingService();
  bool _isLoading = true;
  String _sciCrypto = '0';
  String _alignment = '0';

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  Future<void> _loadSleepData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _sciCrypto = '${_sleepService.getSleepConsistencyIndex()}';
        _alignment = '${_sleepService.getCircadianAlignmentScore()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Analytics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: 'Sleep Consistency Index (SCI)',
                    score: _sciCrypto,
                    subtitle: '30-day sleep pattern consistency (0-100)',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Circadian Alignment Score',
                    score: _alignment,
                    subtitle: 'Alignment with natural light cycles (0-100)',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildChartRow('Sleep Duration (hrs)', [7.2, 6.8, 7.5, 7.0, 7.8]),
                  const SizedBox(height: 16),
                  _buildChartRow('Sleep Debt (mins)', [15, 25, 5, 10, 0]),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Deep Sleep (N3)',
                          '28% of total',
                          Icons.wb_sunny,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'REM Sleep',
                          '20% of total',
                          Icons.face_retouching_natural,
                          Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required String score,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      color: Colors.black.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  score,
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartRow(String label, List<double> data) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: data.asMap().entries.map((entry) {
                final idx = entry.key;
                final value = entry.value;
                return Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20,
                        child: LinearProgressIndicator(
                          value: value / max,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getChartColor(idx),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChartColor(int idx) {
    final colors = [Colors.yellow, Colors.cyan, Colors.green, Colors.purple, Colors.orange];
    return colors[idx % colors.length];
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: Colors.black.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
