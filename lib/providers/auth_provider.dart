import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final SessionService _sessionService;

  bool _isLoggedIn = false;
  String? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    DatabaseHelper? dbHelper,
    SessionService? sessionService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _sessionService = sessionService ?? SessionService();

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _sessionService.isLoggedIn();
      if (_isLoggedIn) {
        _currentUser = await _sessionService.getCurrentUser();
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = UserModel(
        username: username.trim(),
        password: password,
      );
      await _dbHelper.registerUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthDuplicateException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal melakukan registrasi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _dbHelper.loginUser(username.trim(), password);
      if (user != null) {
        await _sessionService.saveSession(username: user.username);
        _isLoggedIn = true;
        _currentUser = user.username;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Username atau password salah!';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _sessionService.clearSession();
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
