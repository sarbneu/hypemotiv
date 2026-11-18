/// Main dashboard shell with the four-tab cyberpunk navigation.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/alarm_active_screen.dart';
import 'package:hypemotiv/screens/arena_screen.dart';
import 'package:hypemotiv/screens/sleep_matrix_screen.dart';
import 'package:hypemotiv/screens/sound_lab_screen.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    ArenaScreen(),
    SoundLabScreen(),
    AlarmActiveScreen(),
    SleepMatrixScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.bg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: CyberTheme.panel,
        selectedItemColor: CyberTheme.lime,
        unselectedItemColor: CyberTheme.muted,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          letterSpacing: 1.4,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'ALARMS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.graphic_eq),
            label: 'BOUND LAB',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'MISSIONS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'STATS',
          ),
        ],
      ),
    );
  }
}
