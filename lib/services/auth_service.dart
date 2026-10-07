import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:filetrack/models/user.dart';
import 'package:filetrack/services/database_helper.dart';

enum LoginResult {
  success,
  mustChangePin,
  invalidCredentials,
  userNotFound,
}

class AuthService {
  static final AuthService instance = AuthService._init();
  User? _currentUser;

  AuthService._init();

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<LoginResult> login(String userId, String pin) async {
    final user = await DatabaseHelper.instance.getUserById(userId.trim().toUpperCase());
    if (user == null) {
      return LoginResult.userNotFound;
    }

    final inputHash = hashPin(pin);
    if (user.pinHash != inputHash) {
      return LoginResult.invalidCredentials;
    }

    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_user_id', user.id);

    if (user.mustChangePin) {
      return LoginResult.mustChangePin;
    }

    return LoginResult.success;
  }

  Future<bool> changePin({required String oldPin, required String newPin}) async {
    if (_currentUser == null) return false;

    final oldHash = hashPin(oldPin);
    if (_currentUser!.pinHash != oldHash) {
      return false; // Ancien PIN incorrect
    }

    final newHash = hashPin(newPin);
    final updatedUser = User(
      id: _currentUser!.id,
      name: _currentUser!.name,
      serviceId: _currentUser!.serviceId,
      pinHash: newHash,
      role: _currentUser!.role,
      mustChangePin: false,
    );

    await DatabaseHelper.instance.updateUser(updatedUser);
    _currentUser = updatedUser;
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_user_id');
  }

  Future<User?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('logged_user_id');
    if (savedUserId != null) {
      final user = await DatabaseHelper.instance.getUserById(savedUserId);
      if (user != null && !user.mustChangePin) {
        _currentUser = user;
        return user;
      }
    }
    return null;
  }
}
