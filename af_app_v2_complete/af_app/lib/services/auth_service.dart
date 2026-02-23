import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// ------------------------------------------------------------------
// DEBUG CONFIGURATION
// Set to true while developing so that authentication screens are
// skipped and sign‑in/up logic is disabled.  Remove or set to false
// before releasing the app.
const bool kAuthDisabledForDebug = true;
// ------------------------------------------------------------------

// Add to pubspec.yaml dependencies: crypto: ^3.0.3

class AuthUser {
  final String id;
  final String name;
  final String email;

  const AuthUser({required this.id, required this.name, required this.email});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email};

  factory AuthUser.fromMap(Map<String, dynamic> m) =>
      AuthUser(id: m['id'], name: m['name'], email: m['email']);
}

class AuthService extends ChangeNotifier {
  static const _usersBox = 'auth_users';
  static const _sessionBox = 'auth_session';

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // ── Init ──────────────────────────────────────────────────
  static Future<void> initBoxes() async {
    await Hive.openBox(_usersBox);
    await Hive.openBox(_sessionBox);
  }

  Future<void> restoreSession() async {
    final box = Hive.box(_sessionBox);
    final map = box.get('current_user');
    if (map != null) {
      _currentUser = AuthUser.fromMap(Map<String, dynamic>.from(map));
      notifyListeners();
    }
  }

  // ── Sign up ────────────────────────────────────────────────
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (kAuthDisabledForDebug) {
      // during debug mode just create a dummy user and succeed
      _currentUser ??=
          const AuthUser(id: 'debug', name: 'Debug User', email: 'debug@local');
      notifyListeners();
      return null;
    }

    final box = Hive.box(_usersBox);
    final key = email.toLowerCase().trim();

    if (box.containsKey(key)) {
      return 'An account with this email already exists.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = _hash(password);

    await box.put(key, {
      'id': id,
      'name': name.trim(),
      'email': key,
      'hash': hash,
    });

    final user = AuthUser(id: id, name: name.trim(), email: key);
    await _saveSession(user);
    _currentUser = user;
    notifyListeners();
    return null; // null = success
  }

  // ── Sign in ────────────────────────────────────────────────
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    if (kAuthDisabledForDebug) {
      _currentUser ??=
          const AuthUser(id: 'debug', name: 'Debug User', email: 'debug@local');
      notifyListeners();
      return null;
    }

    final box = Hive.box(_usersBox);
    final key = email.toLowerCase().trim();
    final data = box.get(key);

    if (data == null) return 'No account found with this email.';

    final map = Map<String, dynamic>.from(data);
    final hash = _hash(password);
    if (map['hash'] != hash) return 'Incorrect password.';

    final user = AuthUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
    );
    await _saveSession(user);
    _currentUser = user;
    notifyListeners();
    return null;
  }

  // ── Sign out ───────────────────────────────────────────────
  Future<void> signOut() async {
    await Hive.box(_sessionBox).delete('current_user');
    _currentUser = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────
  Future<void> _saveSession(AuthUser user) async {
    await Hive.box(_sessionBox).put('current_user', user.toMap());
  }

  String _hash(String password) {
    final bytes = utf8.encode('${password}af_screen_salt_2024');
    return sha256.convert(bytes).toString();
  }
}
