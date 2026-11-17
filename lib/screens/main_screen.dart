/// Main screen with bottom navigation.
import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/alarm_screen.dart';
import 'package:hypemotiv/screens/checklist_screen.dart';
import 'package:hypemotiv/screens/sleep_screen.dart';
import 'package:hypemotiv/screens/streak_screen.dart';
import 'package:hypemotiv/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AlarmScreen(),
    ChecklistScreen(),
    SleepScreen(),
    StreakScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Checklist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nights_stay),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fireworthiness),
            label: 'Streak',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
