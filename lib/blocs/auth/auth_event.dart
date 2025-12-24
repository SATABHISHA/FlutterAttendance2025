import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String corpId;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    required this.corpId,
  });

  @override
  List<Object?> get props => [email, password, corpId];
}

class AuthBiometricLoginRequested extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String companyId;
  final String companyName;
  final String corpId;
  final bool isAdmin;
  final bool isSupervisor;
  final String? supervisorId;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.companyId,
    required this.companyName,
    required this.corpId,
    required this.isAdmin,
    required this.isSupervisor,
    this.supervisorId,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        companyId,
        companyName,
        corpId,
        isAdmin,
        isSupervisor,
        supervisorId,
      ];
}

class AuthEnableBiometric extends AuthEvent {
  final bool enable;

  const AuthEnableBiometric({required this.enable});

  @override
  List<Object?> get props => [enable];
}

class AuthEnableFaceId extends AuthEvent {
  final bool enable;

  const AuthEnableFaceId({required this.enable});

  @override
  List<Object?> get props => [enable];
}

class AuthEnableFingerprint extends AuthEvent {
  final bool enable;

  const AuthEnableFingerprint({required this.enable});

  @override
  List<Object?> get props => [enable];
}

class AuthEnablePinPattern extends AuthEvent {
  final bool enable;

  const AuthEnablePinPattern({required this.enable});

  @override
  List<Object?> get props => [enable];
}

class AuthFaceIdLoginRequested extends AuthEvent {}

class AuthFingerprintLoginRequested extends AuthEvent {}

class AuthPinPatternLoginRequested extends AuthEvent {}

class AuthQuickLoginRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthUpdateProfileImage extends AuthEvent {
  final String imagePath;

  const AuthUpdateProfileImage({required this.imagePath});

  @override
  List<Object?> get props => [imagePath];
}

class AuthRefreshUser extends AuthEvent {}
