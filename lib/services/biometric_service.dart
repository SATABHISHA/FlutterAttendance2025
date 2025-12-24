import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';

enum AuthMethod {
  fingerprint,
  faceId,
  iris,
  deviceCredential, // PIN, Pattern, Password
  none,
}

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if any authentication method is available (biometric or device credential)
  Future<bool> isAuthenticationAvailable() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Check if device has PIN/Pattern/Password set up
  Future<bool> isDeviceCredentialAvailable() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      print('getAvailableBiometrics - canCheckBiometrics: $canCheck, isDeviceSupported: $isSupported');
      
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('getAvailableBiometrics - result: $biometrics');
      return biometrics;
    } on PlatformException catch (e) {
      print('getAvailableBiometrics - error: $e');
      return [];
    }
  }

  /// Get all available authentication methods
  Future<List<AuthMethod>> getAvailableAuthMethods() async {
    final methods = <AuthMethod>[];
    
    try {
      final biometrics = await getAvailableBiometrics();
      
      // Debug: print available biometrics
      print('Available biometrics: $biometrics');
      
      // Check for Face ID / Face Unlock
      if (biometrics.contains(BiometricType.face)) {
        methods.add(AuthMethod.faceId);
      }
      
      // Check for Fingerprint / Touch ID
      if (biometrics.contains(BiometricType.fingerprint)) {
        methods.add(AuthMethod.fingerprint);
      }
      
      // On Android, strong/weak biometrics could be either face or fingerprint
      // We need to check what's actually available
      if (Platform.isAndroid) {
        if ((biometrics.contains(BiometricType.strong) ||
             biometrics.contains(BiometricType.weak))) {
          // If we don't have specific face or fingerprint but have strong/weak,
          // consider both as available (Android reports generically sometimes)
          if (!methods.contains(AuthMethod.faceId)) {
            methods.add(AuthMethod.faceId);
          }
          if (!methods.contains(AuthMethod.fingerprint)) {
            methods.add(AuthMethod.fingerprint);
          }
        }
      }
      
      // Check for Iris (some Samsung devices)
      if (biometrics.contains(BiometricType.iris)) {
        methods.add(AuthMethod.iris);
      }
      
      // Device credential is always available if device is secured
      if (await isDeviceCredentialAvailable()) {
        methods.add(AuthMethod.deviceCredential);
      }
      
      return methods;
    } on PlatformException catch (e) {
      print('Error getting auth methods: $e');
      return [];
    }
  }

  /// Check if Face ID / Face Unlock is available
  /// On iOS: Checks for Face ID
  /// On Android: Returns true if device is secured - face unlock (even weak) will work through BiometricPrompt
  Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    print('hasFaceId - Available biometrics: $biometrics');
    
    // On iOS: BiometricType.face indicates Face ID
    if (Platform.isIOS) {
      return biometrics.contains(BiometricType.face);
    } else {
      // On Android: Check for explicit face biometric
      if (biometrics.contains(BiometricType.face)) {
        print('hasFaceId - Android has strong face biometric');
        return true;
      }
      // If no biometrics reported but device is secured, 
      // Android might have weak face unlock enrolled
      // We'll show face option and let the system handle it
      if (biometrics.isEmpty) {
        final isSupported = await _localAuth.isDeviceSupported();
        print('hasFaceId - No biometrics reported, device supported: $isSupported');
        // Return true if device is secured - face might be available
        return isSupported;
      }
      return false;
    }
  }

  /// Check if Touch ID / Fingerprint is available
  Future<bool> hasTouchId() async {
    final biometrics = await getAvailableBiometrics();
    print('hasTouchId - Available biometrics: $biometrics');
    
    if (Platform.isIOS) {
      return biometrics.contains(BiometricType.fingerprint);
    } else {
      // On Android, fingerprint is explicitly reported
      // Also check for strong/weak as fallback for older Android versions
      return biometrics.contains(BiometricType.fingerprint) ||
             biometrics.contains(BiometricType.strong) ||
             biometrics.contains(BiometricType.weak);
    }
  }

  /// Check if PIN/Pattern/Password is available
  Future<bool> hasPinPattern() async {
    try {
      // isDeviceSupported returns true if device has any lock screen (PIN, pattern, password)
      final isSupported = await _localAuth.isDeviceSupported();
      print('hasPinPattern - isDeviceSupported: $isSupported');
      return isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Check if any biometric is available (face, fingerprint, iris, or strong/weak)
  Future<bool> hasAnyBiometric() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  Future<bool> hasIris() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.iris);
  }

  /// Get a human-readable description of available auth methods
  Future<String> getAuthMethodsDescription() async {
    final methods = await getAvailableAuthMethods();
    final descriptions = <String>[];
    
    for (final method in methods) {
      switch (method) {
        case AuthMethod.faceId:
          descriptions.add('Face ID');
          break;
        case AuthMethod.fingerprint:
          descriptions.add('Fingerprint');
          break;
        case AuthMethod.iris:
          descriptions.add('Iris');
          break;
        case AuthMethod.deviceCredential:
          descriptions.add('PIN/Pattern/Password');
          break;
        case AuthMethod.none:
          break;
      }
    }
    
    if (descriptions.isEmpty) {
      return 'No authentication methods available';
    }
    
    return descriptions.join(', ');
  }

  /// Authenticate using biometrics only (fingerprint, face, iris)
  /// Returns false if biometrics not available
  Future<bool> authenticateWithBiometricsOnly({
    String reason = 'Please authenticate using biometrics',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      throw BiometricException(_getErrorMessage(e));
    }
  }

  /// Authenticate specifically with Face ID / Face Unlock
  /// On iOS: Uses Face ID with biometricOnly
  /// On Android: Uses BiometricPrompt which will show face unlock if enrolled
  /// Note: Android weak face unlock requires biometricOnly:false to work
  Future<bool> authenticateWithFace({
    String reason = 'Look at your device to authenticate',
  }) async {
    try {
      final biometrics = await getAvailableBiometrics();
      final isSupported = await _localAuth.isDeviceSupported();
      
      print('authenticateWithFace - biometrics: $biometrics, isSupported: $isSupported');
      
      if (!isSupported) {
        throw BiometricException('Face authentication is not supported');
      }

      if (Platform.isIOS) {
        // On iOS, use Face ID with biometricOnly
        if (!biometrics.contains(BiometricType.face)) {
          throw BiometricException('Face ID is not available on this device');
        }
        return await _localAuth.authenticate(
          localizedReason: 'Authenticate with Face ID',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
            useErrorDialogs: true,
          ),
        );
      } else {
        // On Android: Use biometricOnly:false to allow weak face unlock
        // The system will show face unlock option if enrolled
        // User can also use fingerprint or PIN/Pattern as fallback
        return await _localAuth.authenticate(
          localizedReason: 'Use your face, fingerprint, or device lock to authenticate',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false, // Allow weak biometrics and device credential
            useErrorDialogs: true,
          ),
        );
      }
    } on PlatformException catch (e) {
      print('authenticateWithFace error: ${e.code} - ${e.message}');
      if (e.code == 'NotAvailable') {
        throw BiometricException(
          'Biometric authentication is not available. '
          'Please enroll face or fingerprint in device settings.'
        );
      } else if (e.code == 'NotEnrolled') {
        throw BiometricException(
          'No biometric enrolled. Please enroll face or fingerprint in device settings.'
        );
      }
      throw BiometricException(_getErrorMessage(e));
    }
  }

  /// Authenticate using any available method (biometrics OR device credential)
  /// This will fall back to PIN/Pattern/Password if biometrics fail or are unavailable
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool allowDeviceCredential = true,
  }) async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        throw BiometricException('Device authentication is not supported');
      }

      // First try biometrics, allow fallback to device credential
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !allowDeviceCredential, // If false, allows PIN/Pattern fallback
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      // If biometric-only fails, try with device credential
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        if (allowDeviceCredential) {
          return await authenticateWithDeviceCredential(reason: reason);
        }
      }
      throw BiometricException(_getErrorMessage(e));
    }
  }

  /// Authenticate specifically with device credential (PIN/Pattern/Password)
  Future<bool> authenticateWithDeviceCredential({
    String reason = 'Please enter your PIN, pattern, or password',
  }) async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        throw BiometricException('Device credential authentication is not supported');
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // This allows device credential
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      throw BiometricException(_getErrorMessage(e));
    }
  }

  /// Smart authenticate - tries best available method
  /// Priority: Face ID > Fingerprint > Iris > Device Credential
  Future<AuthResult> smartAuthenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final methods = await getAvailableAuthMethods();
      
      if (methods.isEmpty) {
        return AuthResult(
          success: false,
          method: AuthMethod.none,
          message: 'No authentication method available. Please set up device security.',
        );
      }

      // Determine primary method for messaging
      AuthMethod primaryMethod = methods.first;
      String authReason = reason;
      
      if (methods.contains(AuthMethod.faceId)) {
        primaryMethod = AuthMethod.faceId;
        authReason = 'Authenticate with Face ID';
      } else if (methods.contains(AuthMethod.fingerprint)) {
        primaryMethod = AuthMethod.fingerprint;
        authReason = 'Authenticate with fingerprint';
      } else if (methods.contains(AuthMethod.iris)) {
        primaryMethod = AuthMethod.iris;
        authReason = 'Authenticate with iris scan';
      } else {
        primaryMethod = AuthMethod.deviceCredential;
        authReason = 'Enter your PIN, pattern, or password';
      }

      final success = await _localAuth.authenticate(
        localizedReason: authReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow fallback to device credential
          useErrorDialogs: true,
        ),
      );

      return AuthResult(
        success: success,
        method: primaryMethod,
        message: success ? 'Authentication successful' : 'Authentication failed',
      );
    } on PlatformException catch (e) {
      return AuthResult(
        success: false,
        method: AuthMethod.none,
        message: _getErrorMessage(e),
      );
    }
  }

  String _getErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'Authentication is not available on this device';
      case 'NotEnrolled':
        return 'No authentication method enrolled. Please set up device security in settings';
      case 'LockedOut':
        return 'Too many attempts. Please try again later';
      case 'PermanentlyLockedOut':
        return 'Authentication is permanently locked. Please unlock your device first';
      case 'PasscodeNotSet':
        return 'No passcode set. Please set up a PIN, pattern, or password in device settings';
      case 'OtherOperatingSystem':
        return 'This device does not support authentication';
      default:
        return e.message ?? 'Authentication failed. Please try again';
    }
  }

  Future<void> cancelAuthentication() async {
    await _localAuth.stopAuthentication();
  }
}

class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final bool success;
  final AuthMethod method;
  final String message;

  AuthResult({
    required this.success,
    required this.method,
    required this.message,
  });
}
