library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/app_root.dart';
import 'package:hypemotiv/screens/checklist_screen.dart';
import 'package:hypemotiv/screens/settings_screen.dart';
import 'package:hypemotiv/screens/sensor_status_screen.dart';
import 'package:hypemotiv/screens/sleep_tracking_screen.dart';
import 'package:hypemotiv/screens/streak_screen.dart';
import 'package:hypemotiv/services/auth_service.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:hypemotiv/services/notification_service.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionLabel(context, 'Explore'),
            const SizedBox(height: 8),
            _buildNavCard(
              context: context,
              icon: Icons.checklist_rounded,
              title: 'Daily checklist',
              subtitle: 'Track your five daily habits',
              destination: const ChecklistScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              icon: Icons.local_fire_department_rounded,
              title: 'My streak',
              subtitle: 'See your current and longest streaks',
              destination: const StreakScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle: 'Sync, sound and account preferences',
              destination: const SettingsScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              icon: Icons.bedtime_rounded,
              title: 'Sleep tracking',
              subtitle: 'Start a session, log a night, review history',
              destination: const SleepTrackingScreen(),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel(context, 'Tools'),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.mail_outline_rounded, color: colors.primary),
                title: const Text('Accountability email'),
                subtitle: const Text('Send a real check-in email via the backend'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEmailDialog(context),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.volume_up_rounded, color: colors.primary),
                title: const Text('Test alarm sound'),
                subtitle: const Text('Bundled sound - no internet needed'),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () => _testAlarmSound(context),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.notifications_active_outlined, color: colors.primary),
                title: const Text('Test alarm now'),
                subtitle: const Text('Sound, vibration and notification together'),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () => _testAlarmNow(context),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.sensors_outlined, color: colors.primary),
                title: const Text('Sensors and detection'),
                subtitle: const Text('Check motion, camera and image detection'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const SensorStatusScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: colors.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: colors.primary, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Data syncs to Oracle through the Node backend when '
                        'configured. Without it, the app keeps working '
                        'offline and saves everything on this device.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                subtitle: const Text('Return to the sign-in screen'),
                onTap: () async {
                  await AuthService().signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const AppRoot(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<Widget>(builder: (_) => destination),
          );
        },
      ),
    );
  }

  Future<void> _testAlarmNow(BuildContext context) async {
    await AudioService().play(AudioService.fallbackSoundUrl);
    await NotificationService().showImmediate(
      title: 'Alarm test',
      body: 'Your alarm can ring and notify you.',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alarm test started')),
    );
  }

  Future<void> _testAlarmSound(BuildContext context) async {
    try {
      await AudioService().playLocalTest();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm sound played')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play alarm sound')),
      );
    }
  }

  Future<void> _showEmailDialog(BuildContext context) async {
    final toController = TextEditingController();
    final subjectController =
        TextEditingController(text: 'HypeMotiv accountability check-in');
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    final bool? sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Accountability email'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: toController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          hintText: 'coach@example.com',
                        ),
                        validator: (value) => (value == null || !value.contains('@'))
                            ? 'Enter a valid email address'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Enter a subject'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Message'),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Write a message'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => sending = true);
                          final result = await HypeApi().sendEmail(
                            to: toController.text.trim(),
                            subject: subjectController.text.trim(),
                            body: messageController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop(result);
                        },
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!context.mounted || sent == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent ? 'Email sent' : 'Could not send email'),
      ),
    );
  }
}
