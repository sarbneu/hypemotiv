library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/sensor_status_service.dart';

class SensorStatusScreen extends StatefulWidget {
  const SensorStatusScreen({super.key});

  @override
  State<SensorStatusScreen> createState() => _SensorStatusScreenState();
}

class _SensorStatusScreenState extends State<SensorStatusScreen> {
  final SensorStatusService _service = SensorStatusService();
  SensorStatus? _status;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final SensorStatus status = await _service.check();
    if (!mounted) return;
    setState(() {
      _status = status;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SensorStatus? status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Sensors and detection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Check what this device and backend can support right now.',
            style: TextStyle(color: Color(0xFF667085)),
          ),
          const SizedBox(height: 16),
          if (_checking) const LinearProgressIndicator(minHeight: 3),
          if (status != null) ...<Widget>[
            ListTile(
              leading: Icon(
                status.accelerometer ? Icons.check_circle : Icons.error_outline,
                color: status.accelerometer ? Colors.green : Colors.orange,
              ),
              title: const Text('Motion sensor'),
              subtitle: Text(
                status.accelerometer
                    ? 'Available — squats and push-ups can be counted.'
                    : 'Not available — manual counting is used.',
              ),
            ),
            ListTile(
              leading: Icon(
                status.cameraCount > 0 ? Icons.check_circle : Icons.error_outline,
                color: status.cameraCount > 0 ? Colors.green : Colors.orange,
              ),
              title: const Text('Camera'),
              subtitle: Text(
                status.cameraCount > 0
                    ? 'Available — $status.cameraCount camera(s) found.'
                    : 'Not available — photo proof needs a camera.',
              ),
            ),
            ListTile(
              leading: Icon(
                status.detector ? Icons.check_circle : Icons.info_outline,
                color: status.detector ? Colors.green : Colors.orange,
              ),
              title: const Text('Toothbrush detection'),
              subtitle: Text(
                status.detector
                    ? 'Live detector configured on the backend.'
                    : 'Not configured — fresh-photo checks are used instead.',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Check again'),
              onPressed: _check,
            ),
          ],
        ],
      ),
    );
  }
}
