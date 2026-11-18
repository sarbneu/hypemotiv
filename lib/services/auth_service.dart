/// Simple local account for the student prototype.
///
/// Credentials are stored on the device only. This is a demo account system,
/// not production authentication — no password is ever sent to a server.
library;

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String userKey = 'hypemotiv_account_user';
  static const String passKey = 'hypemotiv_account_pass';
  static const String sessionKey = 'hypemotiv_session';

  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString(userKey);
    return user != null && user.isNotEmpty;
  }

  Future<String?> savedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userKey);
  }

  Future<void> register(String user, String passcode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, user.trim().toLowerCase());
    await prefs.setString(passKey, passcode);
    await prefs.setString(sessionKey, user.trim().toLowerCase());
  }

  /// Returns true when the handle and passcode match the local account.
  Future<bool> login(String user, String passcode) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString(userKey);
    final storedPass = prefs.getString(passKey);
    if (storedUser == null || storedPass == null) return false;
    final ok = storedUser == user.trim().toLowerCase() && storedPass == passcode;
    if (ok) await prefs.setString(sessionKey, storedUser);
    return ok;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
  }

  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(sessionKey) != null;
  }

  Future<void> resetAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
    await prefs.remove(passKey);
    await prefs.remove(sessionKey);
  }
}
