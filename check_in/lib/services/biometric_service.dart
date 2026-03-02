import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device supports biometric or device PIN auth
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the user to authenticate.
  /// Returns true if authentication succeeded, false otherwise.
  static Future<bool> authenticate({String reason = 'Verify your identity to continue'}) async {
    try {
      final available = await isAvailable();
      if (!available) return true; // device doesn't support it — don't block user

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allows PIN/pattern fallback if no biometrics
          stickyAuth: true,     // keeps prompt alive if user switches apps briefly
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}