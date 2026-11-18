/// HypeMotiv - meme audio alarm, daily habit checklist and streak tracker.
///
/// Architecture:
///  - Flutter app + Hive for offline-first local storage
///  - Node.js/Express REST backend (`oracle-backend/`) hosted on an Oracle Cloud VPS
///  - Oracle Database for relational data and BLOB file storage
///  - nodemailer for accountability email, myinstants scraping and video audio ripping
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/app_root.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/hive_initializer.dart';
import 'package:hypemotiv/services/tts_service.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boxes must be open before any service looks them up.
  await HiveInitializer.init();

  // Non-Hive services are safe to initialise afterwards.
  await AudioService().init();
  await TTSService().init();

  runApp(const HypeMotivApp());
}

class HypeMotivApp extends StatelessWidget {
  const HypeMotivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HypeMotiv',
      debugShowCheckedModeBanner: false,
      theme: CyberTheme.themeData(),
      home: const AppRoot(),
    );
  }
}
