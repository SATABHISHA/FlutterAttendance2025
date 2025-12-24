import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _profileImageKey = 'profile_image_path';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _faceIdEnabledKey = 'face_id_enabled';
  static const String _fingerprintEnabledKey = 'fingerprint_enabled';
  static const String _pinPatternEnabledKey = 'pin_pattern_enabled';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _corpIdKey = 'corp_id';
  static const String _deviceLockedToUserKey = 'device_locked_to_user';
  static const String _lockedUserNameKey = 'locked_user_name';
  static const String _hasCompletedFirstLoginKey = 'has_completed_first_login';
  
  // Secure storage keys for password
  static const String _securePasswordKey = 'secure_user_password';

  final ImagePicker _imagePicker = ImagePicker();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<String?> pickAndSaveProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${directory.path}/$fileName';

        await File(image.path).copy(savedPath);
        await saveProfileImagePath(savedPath);

        return savedPath;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<String?> takeAndSaveProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${directory.path}/$fileName';

        await File(image.path).copy(savedPath);
        await saveProfileImagePath(savedPath);

        return savedPath;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, path);
  }

  Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_profileImageKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await prefs.remove(_profileImageKey);
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Face ID settings
  Future<void> saveFaceIdEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceIdEnabledKey, enabled);
  }

  Future<bool> getFaceIdEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceIdEnabledKey) ?? false;
  }

  // Fingerprint/Touch ID settings
  Future<void> saveFingerprintEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintEnabledKey, enabled);
  }

  Future<bool> getFingerprintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fingerprintEnabledKey) ?? false;
  }

  // PIN/Pattern settings
  Future<void> savePinPatternEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinPatternEnabledKey, enabled);
  }

  Future<bool> getPinPatternEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinPatternEnabledKey) ?? false;
  }

  // Device locking to single user
  Future<void> lockDeviceToUser(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceLockedToUserKey, userId);
    await prefs.setString(_lockedUserNameKey, userName);
  }

  Future<String?> getDeviceLockedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceLockedToUserKey);
  }

  Future<String?> getLockedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockedUserNameKey);
  }

  Future<bool> isDeviceLockedToUser() async {
    final userId = await getDeviceLockedUserId();
    return userId != null && userId.isNotEmpty;
  }

  Future<bool> isDeviceLockedToThisUser(String userId) async {
    final lockedUserId = await getDeviceLockedUserId();
    return lockedUserId == null || lockedUserId.isEmpty || lockedUserId == userId;
  }

  // First login tracking
  Future<void> setFirstLoginCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedFirstLoginKey, true);
  }

  Future<bool> hasCompletedFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedFirstLoginKey) ?? false;
  }

  Future<void> saveUserCredentials({
    required String oderId,
    required String email,
    required String corpId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, oderId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_corpIdKey, corpId);
    // Store password securely
    await _secureStorage.write(key: _securePasswordKey, value: password);
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final password = await _secureStorage.read(key: _securePasswordKey);
    return {
      'userId': prefs.getString(_userIdKey),
      'email': prefs.getString(_userEmailKey),
      'corpId': prefs.getString(_corpIdKey),
      'password': password,
    };
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_corpIdKey);
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_faceIdEnabledKey);
    await prefs.remove(_fingerprintEnabledKey);
    await prefs.remove(_pinPatternEnabledKey);
    await _secureStorage.delete(key: _securePasswordKey);
    // Note: We do NOT clear device lock here - that requires app data clear
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await deleteProfileImage();
    await _secureStorage.deleteAll();
    await prefs.clear();
  }

  // Check if any quick login method is enabled
  Future<bool> isAnyQuickLoginEnabled() async {
    final faceId = await getFaceIdEnabled();
    final fingerprint = await getFingerprintEnabled();
    final pinPattern = await getPinPatternEnabled();
    return faceId || fingerprint || pinPattern;
  }
}
