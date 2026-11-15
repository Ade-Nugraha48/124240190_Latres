import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SessionService {
  SharedPreferences? preferences;

  SessionService({this.preferences});

  Future<SharedPreferences> _getPrefs() async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences!;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
  }

  Future<String?> getCurrentUser() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.prefCurrentUser);
  }

  Future<void> saveSession({required String username}) async {
    final prefs = await _getPrefs();
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setString(AppConstants.prefCurrentUser, username);
  }

  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    await prefs.remove(AppConstants.prefCurrentUser);
  }
}
