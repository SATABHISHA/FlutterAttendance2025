import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final bool faceIdAvailable;
  final bool faceIdEnabled;
  final bool fingerprintAvailable;
  final bool fingerprintEnabled;
  final bool pinPatternAvailable;
  final bool pinPatternEnabled;
  final bool isDeviceLocked;
  final String? lockedUserName;
  final bool hasCompletedFirstLogin;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.faceIdAvailable = false,
    this.faceIdEnabled = false,
    this.fingerprintAvailable = false,
    this.fingerprintEnabled = false,
    this.pinPatternAvailable = false,
    this.pinPatternEnabled = false,
    this.isDeviceLocked = false,
    this.lockedUserName,
    this.hasCompletedFirstLogin = false,
  });

  const AuthState.unknown() : this();

  const AuthState.loading()
      : this(status: AuthStatus.loading);

  const AuthState.authenticated({
    required UserModel user,
    bool biometricAvailable = false,
    bool biometricEnabled = false,
    bool faceIdAvailable = false,
    bool faceIdEnabled = false,
    bool fingerprintAvailable = false,
    bool fingerprintEnabled = false,
    bool pinPatternAvailable = false,
    bool pinPatternEnabled = false,
    bool isDeviceLocked = false,
    String? lockedUserName,
    bool hasCompletedFirstLogin = false,
  }) : this(
          status: AuthStatus.authenticated,
          user: user,
          biometricAvailable: biometricAvailable,
          biometricEnabled: biometricEnabled,
          faceIdAvailable: faceIdAvailable,
          faceIdEnabled: faceIdEnabled,
          fingerprintAvailable: fingerprintAvailable,
          fingerprintEnabled: fingerprintEnabled,
          pinPatternAvailable: pinPatternAvailable,
          pinPatternEnabled: pinPatternEnabled,
          isDeviceLocked: isDeviceLocked,
          lockedUserName: lockedUserName,
          hasCompletedFirstLogin: hasCompletedFirstLogin,
        );

  const AuthState.unauthenticated({
    bool biometricAvailable = false,
    bool biometricEnabled = false,
    bool faceIdAvailable = false,
    bool faceIdEnabled = false,
    bool fingerprintAvailable = false,
    bool fingerprintEnabled = false,
    bool pinPatternAvailable = false,
    bool pinPatternEnabled = false,
    bool isDeviceLocked = false,
    String? lockedUserName,
    bool hasCompletedFirstLogin = false,
  }) : this(
          status: AuthStatus.unauthenticated,
          biometricAvailable: biometricAvailable,
          biometricEnabled: biometricEnabled,
          faceIdAvailable: faceIdAvailable,
          faceIdEnabled: faceIdEnabled,
          fingerprintAvailable: fingerprintAvailable,
          fingerprintEnabled: fingerprintEnabled,
          pinPatternAvailable: pinPatternAvailable,
          pinPatternEnabled: pinPatternEnabled,
          isDeviceLocked: isDeviceLocked,
          lockedUserName: lockedUserName,
          hasCompletedFirstLogin: hasCompletedFirstLogin,
        );

  const AuthState.error(String message)
      : this(
          status: AuthStatus.error,
          errorMessage: message,
        );

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? biometricAvailable,
    bool? biometricEnabled,
    bool? faceIdAvailable,
    bool? faceIdEnabled,
    bool? fingerprintAvailable,
    bool? fingerprintEnabled,
    bool? pinPatternAvailable,
    bool? pinPatternEnabled,
    bool? isDeviceLocked,
    String? lockedUserName,
    bool? hasCompletedFirstLogin,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      faceIdAvailable: faceIdAvailable ?? this.faceIdAvailable,
      faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
      fingerprintAvailable: fingerprintAvailable ?? this.fingerprintAvailable,
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
      pinPatternAvailable: pinPatternAvailable ?? this.pinPatternAvailable,
      pinPatternEnabled: pinPatternEnabled ?? this.pinPatternEnabled,
      isDeviceLocked: isDeviceLocked ?? this.isDeviceLocked,
      lockedUserName: lockedUserName ?? this.lockedUserName,
      hasCompletedFirstLogin: hasCompletedFirstLogin ?? this.hasCompletedFirstLogin,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        biometricAvailable,
        biometricEnabled,
        faceIdAvailable,
        faceIdEnabled,
        fingerprintAvailable,
        fingerprintEnabled,
        pinPatternAvailable,
        pinPatternEnabled,
        isDeviceLocked,
        lockedUserName,
        hasCompletedFirstLogin,
      ];
}
