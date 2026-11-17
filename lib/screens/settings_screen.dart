/// Settings screen - configuration including Oracle connectivity.
import 'package:flutter/material.dart';
import 'package:hypemotiv/services/oracle_service.dart';
import 'package:hypemotiv/utils/oracle_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _oracleStatus = 'Not connected';
  bool _syncEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkOracleStatus();
  }

  Future<void> _checkOracleStatus() async {
    final result = await OracleService.ping();
    if (mounted) {
      setState(() {
        _oracleStatus = '${result['status'].toString()} - ${result['timestamp'].toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Database & Oracle'),
            const SizedBox(height: 12),
            _buildOracleCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('App Settings'),
            const SizedBox(height: 12),
            _buildSwitchListTile(
              title: 'Sync to Oracle',
              subtitle: 'Push local data to Oracle database',
              value: _syncEnabled,
              onChanged: (v) => setState(() => _syncEnabled = v),
            ),
            const SizedBox(height: 12),
            _buildSwitchListTile(
              title: 'Dark Mode',
              subtitle: 'Choose light or dark theme',
              value: true,
              onChanged: (v) {},
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Account'),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Student ID',
              placeholder: 'Enter your student ID',
              value: '2527665',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'College',
              placeholder: 'Enter college name',
              value: 'Patan College for Professional Studies',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Username',
              placeholder: 'Enter your Oracle username',
              value: OracleConfig.oracleUser,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Database Host',
              placeholder: 'Enter Oracle DB host',
              value: OracleConfig.oracleHost,
            ),
            const SizedBox(height: 12),
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            _buildInfoRow('App Name', 'HypeMotiv'),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Student ID', '2527665'),
            _buildInfoRow('College', 'PCPS College, Lalitpur, Nepal'),
            _buildInfoRow('Affiliation', 'University of Bedfordshire'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.yellow,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOracleCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Oracle Database Status',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _oracleStatus.contains('ok') || _oracleStatus.contains('ok')
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _oracleStatus.contains('ok') || _oracleStatus.contains('ok') ? 'Connected' : 'Connecting...',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _oracleStatus,
              style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildRow('Host', OracleConfig.oracleHost),
            _buildRow('Port', OracleConfig.oraclePort.toString()),
            _buildRow('User', OracleConfig.oracleUser),
            _buildRow('Service', OracleConfig.oracleService),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchListTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFFB0B0B0)),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String placeholder,
    required String value,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.yellow),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      obscureText: true,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
