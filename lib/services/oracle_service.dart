library;
import 'dart:convert';
import 'package:http/http.dart' as http;

class OracleService {

  static const String alarmsEndpoint = '/api/alarms';
  static const String checklistsEndpoint = '/api/checklists';
  static const String streaksEndpoint = '/api/streaks';
  static const String quotesEndpoint = '/api/quotes';

  static String get host =>
      String.fromEnvironment('ORACLE_HOST', defaultValue: 'localhost');

  static const int port = 3000;

  static String get baseUrl {
    const configured = String.fromEnvironment('HYPE_API_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/api/?$'), '');
    }
    return 'http://$host:$port';
  }

  static String endpointUrl(String endpoint) => '$baseUrl$endpoint';

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

  static Future<Map<String, dynamic>> fetchSettings(String userId) async {
    return fetch('/api/settings?userId=$userId');
  }

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
