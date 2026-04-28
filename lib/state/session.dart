import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Tiny convenience accessor so screens don't need to know which service
/// owns the current user.
class Session {
  static AppUser require(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      throw StateError('Session.require called when no user is signed in.');
    }
    return user;
  }

  static AppUser? maybe(BuildContext context) =>
      context.read<AuthService>().currentUser;
}
