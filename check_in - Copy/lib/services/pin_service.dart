import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Handles all PIN operations: save, verify, check existence, and reset via DOB.
/// PIN is SHA-256 hashed before storage.
/// Uses flutter_secure_storage so the hash is encrypted on the device.
class PinService {
  static const _storage = FlutterSecureStorage();

  static const _pinKey = 'checkin_user_pin';
  static const _dobKey = 'checkin_user_dob'; // stored as YYYY-MM-DD

  // ── Hashing ──────────────────────────────────────────────────────────────────

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ── PIN ──────────────────────────────────────────────────────────────────────

  /// Returns true if a PIN has been set
  static Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Hashes and saves the PIN
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: _hashPin(pin));
  }

  /// Hashes the entered PIN and compares against stored hash
  static Future<bool> verifyPin(String enteredPin) async {
    final storedHash = await _storage.read(key: _pinKey);
    return storedHash == _hashPin(enteredPin);
  }

  // ── Date of Birth (for PIN reset) ────────────────────────────────────────────

  /// Saves the user's DOB as 'YYYY-MM-DD' (call during onboarding)
  static Future<void> saveDob(DateTime dob) async {
    final dobString =
        '${dob.year.toString().padLeft(4, '0')}-'
        '${dob.month.toString().padLeft(2, '0')}-'
        '${dob.day.toString().padLeft(2, '0')}';
    await _storage.write(key: _dobKey, value: dobString);
  }

  /// Returns true if the entered DOB matches the stored DOB
  static Future<bool> verifyDob(DateTime enteredDob) async {
    final stored = await _storage.read(key: _dobKey);
    if (stored == null) return false;
    final enteredString =
        '${enteredDob.year.toString().padLeft(4, '0')}-'
        '${enteredDob.month.toString().padLeft(2, '0')}-'
        '${enteredDob.day.toString().padLeft(2, '0')}';
    return stored == enteredString;
  }

  /// Deletes PIN and DOB — call only when wiping all app data
  static Future<void> clearAll() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _dobKey);
  }
}
