import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _keyName = 'checkin_hive_encryption_key';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // uses Android Keystore
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // iOS Keychain
    ),
  );

  /// Returns the AES-256 encryption key for Hive.
  /// Generates a new one on first launch and stores it securely.
  /// On subsequent launches, retrieves the stored key.
  static Future<List<int>> getEncryptionKey() async {
    // Check if key already exists
    String? existingKey = await _secureStorage.read(key: _keyName);

    if (existingKey != null) {
      // Key exists — decode and return it
      return base64Url.decode(existingKey);
    }

    // First launch — generate a new 256-bit (32 byte) random key
    final key = _generateSecureKey();

    // Store it securely in Android Keystore / iOS Keychain
    await _secureStorage.write(key: _keyName, value: base64Url.encode(key));

    return key;
  }

  /// Generates a cryptographically secure random 32-byte key
  static List<int> _generateSecureKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }
}
