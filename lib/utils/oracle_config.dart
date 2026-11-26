library;
class OracleConfig {
  static const String oracleUser = 'your_username';
  static const String oraclePassword = 'your_password';
  static const String oracleHost = 'localhost';
  static const String oraclePort = '1521';
  static const String oracleService = 'ORCL';
  static const String oracleConnectString = 'localhost:1521/ORCL';

  static const String apiBaseUrl = String.fromEnvironment(
    'HYPE_API_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  static const String alarmsEndpoint = '$apiBaseUrl/alarms';
  static const String checklistsEndpoint = '$apiBaseUrl/checklists';
  static const String streaksEndpoint = '$apiBaseUrl/streaks';
  static const String quotesEndpoint = '$apiBaseUrl/quotes';

  static const String soundsEndpoint = '$apiBaseUrl/sounds';
  static const String filesEndpoint = '$apiBaseUrl/files';
  static const String ripEndpoint = '$apiBaseUrl/rip';
  static const String emailEndpoint = '$apiBaseUrl/email/send';

  static const String appName = 'HypeMotiv';
  static const String studentId = '2527665';
  static const String college = 'Patan College for Professional Studies';
  static const String affiliation = 'University of Bedfordshire';

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
