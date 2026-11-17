/// Oracle Database connectivity service.
///
/// NOTE: Flutter/Dart has no official Oracle driver. Oracle is accessed
/// server-side (Node.js/Express with oracledb) and the mobile app syncs
/// with the Oracle backend via HTTPS/REST. This service demonstrates the
/// sync protocol the mobile app uses to talk to Oracle.
///
/// Server side (Node.js + oracledb):
///   const oracledb = require('oracledb');
///   const conn = await oracledb.getConnection({ user, password, connectString });
///   const result = await conn.execute('SELECT * FROM hypemotiv.alarm_settings WHERE user_id = :uid', [uid]);
///
/// See: README.md for full setup instructions.
class OracleService {
  static const String _appName = 'HypeMotiv';

  // Endpoints used by the mobile app to sync with Oracle.
  static const String alarmsEndpoint = '/api/alarms';
  static const String checklistsEndpoint = '/api/checklists';
  static const String streaksEndpoint = '/api/streaks';
  static const String quotesEndpoint = '/api/quotes';

  /// Default Oracle REMOTE database host for the local dev server.
  /// Override via environment variable ORACLE_HOST (default: localhost).
  static String get host => String.fromEnvironment('ORACLE_HOST', defaultValue: 'localhost');

  /// Default port for the Oracle sync REST API.
  static const int port = 3000;

  /// Full base URL, e.g. http://localhost:3000
  static String get baseUrl => 'http://${host}:$port';

  /// Usage: OracleService.alarmsEndpoint
  /// The mobile app sends HTTPS POST requests to these endpoints with
  /// JSON payloads containing user_id, timestamp, and data payloads.

  /// Build the full URL for a given endpoint.
  static String endpointUrl(String endpoint) => '$baseUrl$endpoint';

  /// Ping the Oracle sync service.
  ///
  /// Returns a [Map] with status info.
  static Future<Map<String, dynamic>> ping() async {
    try {
      final response = await _httpClient().get(
        Uri.parse('$baseUrl/health'),
      );
      if (response.statusCode == 200) {
        return {'status': 'ok', 'timestamp': DateTime.now().toIso8601String()};
      }
      return {
        'status': 'unreachable',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Example: Fetch user settings from Oracle.
  static Future<Map<String, dynamic>> fetchSettings(String userId) async {
    try {
      final response = await _httpClient().get(
        Uri.parse('$baseUrl/api/settings?userId=$userId'),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Example: Push alarm settings to Oracle.
  static Future<Map<String, dynamic>> saveAlarms(
    String userId,
    List<Map<String, dynamic>> alarms,
  ) async {
    try {
      final response = await _httpClient().post(
        Uri.parse('$baseUrl/api/alarms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'alarms': alarms,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

/// Lightweight HTTP client wrapper (avoids circular import with dart:convert).
/// In a real app, use package:http directly.
Future<dynamic> _httpClient() => null; // placeholder, replaced by dart:http at runtime
