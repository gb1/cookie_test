import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show AuthApiException;

import '../models/app_user.dart';

/// Auth backed by Supabase. The user's app-level profile (display name,
/// role, vessel info) lives in the `public.profiles` table; we hydrate it
/// after every auth change.
class AuthService extends ChangeNotifier {
  AuthService(this._client) {
    _authSub = _client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session == null) {
        _setUser(null);
      } else {
        _hydrate(session.user.id);
      }
    });

    final existing = _client.auth.currentSession;
    if (existing != null) {
      _hydrate(existing.user.id);
    }
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _authSub;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> _hydrate(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        // Trigger usually creates this row; fall back to auth metadata.
        final auth = _client.auth.currentUser;
        if (auth == null) return;
        _setUser(AppUser(
          id: auth.id,
          email: auth.email ?? '',
          name: auth.userMetadata?['name'] as String? ??
              (auth.email?.split('@').first ?? 'User'),
          role: UserRole.passenger,
        ));
        return;
      }
      _setUser(_userFromRow(row));
    } catch (_) {
      // Network blip - leave the existing user in place.
    }
  }

  AppUser _userFromRow(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      name: row['name'] as String? ?? '',
      role: row['role'] == 'driver' ? UserRole.driver : UserRole.passenger,
      vesselName: row['vessel_name'] as String?,
      vesselCapacity: row['vessel_capacity'] as int?,
    );
  }

  void _setUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Sign-up did not return a user.');
      }
      // The DB trigger creates the profile row; hydrate to pick it up.
      await _hydrate(user.id);
      return _currentUser ??
          AppUser(
            id: user.id,
            email: email.trim(),
            name: name.trim(),
            role: UserRole.passenger,
          );
    } on sb.AuthApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Invalid email or password.');
      }
      await _hydrate(user.id);
      return _currentUser ??
          AppUser(
            id: user.id,
            email: email.trim(),
            name: email.split('@').first,
            role: UserRole.passenger,
          );
    } on sb.AuthApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _setUser(null);
  }

  Future<void> updateProfile({
    String? name,
    UserRole? role,
    String? vesselName,
    int? vesselCapacity,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final patch = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (role != null) 'role': role.name,
      if (vesselName != null) 'vessel_name': vesselName.trim(),
      if (vesselCapacity != null) 'vessel_capacity': vesselCapacity,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (patch.length == 1) return; // only updated_at

    await _client.from('profiles').update(patch).eq('id', user.id);
    await _hydrate(user.id);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

