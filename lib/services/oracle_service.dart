/// Oracle Database connectivity service.
library;
import 'dart:convert';
import 'package:http/http.dart' as http;

class OracleService {

  // Endpoints used by the mobile app to sync with Oracle.
  static const String alarmsEndpoint = '/api/alarms';
  static const String checklistsEndpoint = '/api/checklists';
  static const String streaksEndpoint = '/api/streaks';
  static const String quotesEndpoint = '/api/quotes';

  /// Default Oracle REMOTE database host for the local dev server.
  /// Override via environment variable ORACLE_HOST (default: localhost).
  static String get host =>
      String.fromEnvironment('ORACLE_HOST', defaultValue: 'localhost');

  /// Default port for the Oracle sync REST API.
  static const int port = 3000;

  /// Full base URL, e.g. http://localhost:3000 or https://vps.example.com
  static String get baseUrl {
    const configured = String.fromEnvironment('HYPE_API_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/api/?$'), '');
    }
    return 'http://$host:$port';
  }

  /// Build the full URL for a given endpoint.
  static String endpointUrl(String endpoint) => '$baseUrl$endpoint';

  /// Fetch data from Oracle via REST API.
  static Future<Map<String, dynamic>> fetch(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Ping the Oracle sync service health endpoint.
  /// Returns a [Map] with status info.
  static Future<Map<String, dynamic>> ping() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final oracle = (data['oracle'] ?? 'unknown').toString();
        return {
          'status': oracle == 'connected' ? 'ok' : 'offline',
          'oracle': oracle,
          'filesBackend': (data['filesBackend'] ?? 'unknown').toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
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
    return fetch('/api/settings?userId=$userId');
  }

  /// Push alarm settings to Oracle.
  static Future<Map<String, dynamic>> saveAlarms(
    String userId,
    List<Map<String, dynamic>> alarms,
  ) async {
    try {
      final response = await http.post(
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
