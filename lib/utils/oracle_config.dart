/// Oracle configuration constants.
///
/// These are placeholders - replace with your actual Oracle connection details.
/// The HypeMotiv app connects to Oracle via a REST API (Node.js + oracledb)
/// since Flutter has no native Oracle driver.
class OracleConfig {
  // Database connection details
  static const String oracleUser = 'your_username';
  static const String oraclePassword = 'your_password';
  static const String oracleHost = 'localhost';
  static const String oraclePort = '1521';
  static const String oracleService = 'ORCL';
  static const String oracleConnectString = 'localhost:1521/ORCL';

  // REST API endpoints for the mobile app to sync with Oracle.
  // Override at build time for a real device / emulator:
  //   flutter run --dart-define=HYPE_API_URL=http://10.0.2.2:3000/api
  static const String apiBaseUrl = String.fromEnvironment(
    'HYPE_API_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  static const String alarmsEndpoint = '$apiBaseUrl/alarms';
  static const String checklistsEndpoint = '$apiBaseUrl/checklists';
  static const String streaksEndpoint = '$apiBaseUrl/streaks';
  static const String quotesEndpoint = '$apiBaseUrl/quotes';

  // Extended endpoints (scraping, Oracle BLOB files, video rip, Node email)
  static const String soundsEndpoint = '$apiBaseUrl/sounds';
  static const String filesEndpoint = '$apiBaseUrl/files';
  static const String ripEndpoint = '$apiBaseUrl/rip';
  static const String emailEndpoint = '$apiBaseUrl/email/send';

  // App metadata
  static const String appName = 'HypeMotiv';
  static const String studentId = '2527665';
  static const String college = 'Patan College for Professional Studies';
  static const String affiliation = 'University of Bedfordshire';

  // Suggested demo alarm schedules for the alarm screen
  static const List<Map<String, dynamic>> suggestedAlarms = [
    {
      'title': 'Morning Wake Up',
      'time': '07:00 AM',
      'audioUrl': 'https://www.soundjay.com/alarms/sounds/bell-1.mp3',
      'notes': 'Gentle bell alarm for morning'
    },
    {
      'title': 'Midday Reminder',
      'time': '12:00 PM',
      'audioUrl': 'https://www.soundjay.com/alarms/sounds/bell-2.mp3',
      'notes': 'Lunch break reminder'
    },
    {
      'title': 'Evening Wind Down',
      'time': '09:00 PM',
      'audioUrl': 'https://www.soundjay.com/alarms/sounds/bell-3.mp3',
      'notes': 'End of day relaxation alarm'
    }
  ];
}
