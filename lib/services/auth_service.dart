import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';

/// Mock authentication. Stores users in `shared_preferences` keyed by email.
/// Passwords are stored as-is for the demo only - this is not secure and is
/// not how a real auth flow should work.
class AuthService extends ChangeNotifier {
  AuthService(this._prefs) {
    _restore();
  }

  static const _kCurrentUser = 'auth.currentUser';
  static const _kUsers = 'auth.users';
  static const _kPasswords = 'auth.passwords';

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  void _restore() {
    final raw = _prefs.getString(_kCurrentUser);
    if (raw != null && raw.isNotEmpty) {
      _currentUser = AppUser.decode(raw);
    }
  }

  Map<String, AppUser> _allUsers() {
    final raw = _prefs.getString(_kUsers);
    if (raw == null || raw.isEmpty) return <String, AppUser>{};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) =>
        MapEntry(k, AppUser.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> _saveUsers(Map<String, AppUser> users) async {
    final json = users.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_kUsers, jsonEncode(json));
  }

  Map<String, String> _allPasswords() {
    final raw = _prefs.getString(_kPasswords);
    if (raw == null || raw.isEmpty) return <String, String>{};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _savePasswords(Map<String, String> pw) async {
    await _prefs.setString(_kPasswords, jsonEncode(pw));
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final users = _allUsers();
    final key = email.trim().toLowerCase();
    if (users.containsKey(key)) {
      throw const AuthException('An account with that email already exists.');
    }
    final user = AppUser(
      id: _uuid.v4(),
      email: key,
      name: name.trim(),
      role: UserRole.passenger,
    );
    users[key] = user;
    final pws = _allPasswords()..[key] = password;
    await _saveUsers(users);
    await _savePasswords(pws);
    await _setCurrent(user);
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    final users = _allUsers();
    final pws = _allPasswords();
    final user = users[key];
    if (user == null || pws[key] != password) {
      throw const AuthException('Invalid email or password.');
    }
    await _setCurrent(user);
    return user;
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _prefs.remove(_kCurrentUser);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    UserRole? role,
    String? vesselName,
    int? vesselCapacity,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    final updated = user.copyWith(
      name: name,
      role: role,
      vesselName: vesselName,
      vesselCapacity: vesselCapacity,
    );
    final users = _allUsers()..[user.email] = updated;
    await _saveUsers(users);
    await _setCurrent(updated);
  }

  Future<void> _setCurrent(AppUser user) async {
    _currentUser = user;
    await _prefs.setString(_kCurrentUser, user.encode());
    notifyListeners();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
