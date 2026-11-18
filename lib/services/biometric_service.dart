import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if hardware supports biometrics and device has enrolled biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric check error: $e');
      return false;
    }
  }

  /// Trigger biometric prompt with password/PIN fallback
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to authenticate to NeighborShare',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows device PIN/pattern fallback
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }
}