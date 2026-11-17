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
  static const String oraclePort = 1521;
  static const String oracleService = 'ORCL';
  static const String oracleConnectString = 'localhost:1521/ORCL';

  // REST API endpoints for the mobile app to sync with Oracle
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static const String alarmsEndpoint = '$apiBaseUrl/alarms';
  static const String checklistsEndpoint = '$apiBaseUrl/checklists';
  static const String streaksEndpoint = '$apiBaseUrl/streaks';
  static const String quotesEndpoint = '$apiBaseUrl/quotes';

  // App metadata
  static const String appName = 'HypeMotiv';
  static const String studentId = '2527665';
  static const String college = 'Patan College for Professional Studies';
  static const String affiliation = 'University of Bedfordshire';
}
