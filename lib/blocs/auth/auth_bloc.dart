import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final BiometricService _biometricService;
  final StorageService _storageService;

  AuthBloc({
    required AuthService authService,
    required BiometricService biometricService,
    required StorageService storageService,
  })  : _authService = authService,
        _biometricService = biometricService,
        _storageService = storageService,
        super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthBiometricLoginRequested>(_onAuthBiometricLoginRequested);
    on<AuthFaceIdLoginRequested>(_onAuthFaceIdLoginRequested);
    on<AuthFingerprintLoginRequested>(_onAuthFingerprintLoginRequested);
    on<AuthPinPatternLoginRequested>(_onAuthPinPatternLoginRequested);
    on<AuthQuickLoginRequested>(_onAuthQuickLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthEnableBiometric>(_onAuthEnableBiometric);
    on<AuthEnableFaceId>(_onAuthEnableFaceId);
    on<AuthEnableFingerprint>(_onAuthEnableFingerprint);
    on<AuthEnablePinPattern>(_onAuthEnablePinPattern);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUpdateProfileImage>(_onAuthUpdateProfileImage);
    on<AuthRefreshUser>(_onAuthRefreshUser);
  }

  Future<AuthState> _getFullAuthState({
    required AuthStatus status,
    UserModel? user,
    String? errorMessage,
  }) async {
    final authAvailable = await _biometricService.isAuthenticationAvailable();
    final biometricEnabled = await _storageService.getBiometricEnabled();
    final hasFaceId = await _biometricService.hasFaceId();
    final hasFingerprint = await _biometricService.hasTouchId();
    final hasPinPattern = await _biometricService.hasPinPattern();
    final faceIdEnabled = await _storageService.getFaceIdEnabled();
    final fingerprintEnabled = await _storageService.getFingerprintEnabled();
    final pinPatternEnabled = await _storageService.getPinPatternEnabled();
    final isDeviceLocked = await _storageService.isDeviceLockedToUser();
    final lockedUserName = await _storageService.getLockedUserName();
    final hasCompletedFirstLogin = await _storageService.hasCompletedFirstLogin();

    return AuthState(
      status: status,
      user: user,
      errorMessage: errorMessage,
      biometricAvailable: authAvailable,
      biometricEnabled: biometricEnabled,
      faceIdAvailable: hasFaceId,
      faceIdEnabled: faceIdEnabled,
      fingerprintAvailable: hasFingerprint,
      fingerprintEnabled: fingerprintEnabled,
      pinPatternAvailable: hasPinPattern,
      pinPatternEnabled: pinPatternEnabled,
      isDeviceLocked: isDeviceLocked,
      lockedUserName: lockedUserName,
      hasCompletedFirstLogin: hasCompletedFirstLogin,
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      if (_authService.currentUser != null) {
        final user = await _authService.getCurrentUserData();
        if (user != null) {
          emit(await _getFullAuthState(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(await _getFullAuthState(status: AuthStatus.unauthenticated));
        }
      } else {
        emit(await _getFullAuthState(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      // Check if device is locked to another user
      final isLocked = await _storageService.isDeviceLockedToUser();
      if (isLocked) {
        final lockedUserId = await _storageService.getDeviceLockedUserId();
        final lockedUserName = await _storageService.getLockedUserName();
        
        // First attempt to login to verify if same user
        final user = await _authService.signInWithEmailPassword(
          email: event.email,
          password: event.password,
          corpId: event.corpId,
        );

        if (user != null) {
          if (lockedUserId != user.id) {
            // Different user trying to login on locked device
            await _authService.signOut();
            emit(AuthState.error(
              'This device is registered to $lockedUserName. '
              'To use a different account, please clear app data or reinstall the app.',
            ));
            return;
          }
          
          // Same user - proceed with login
          await _storageService.saveUserCredentials(
            oderId: user.id,
            email: user.email,
            corpId: user.corpId,
            password: event.password,
          );

          emit(await _getFullAuthState(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(const AuthState.error('Login failed'));
        }
        return;
      }

      // First login on device
      final user = await _authService.signInWithEmailPassword(
        email: event.email,
        password: event.password,
        corpId: event.corpId,
      );

      if (user != null) {
        // Save credentials
        await _storageService.saveUserCredentials(
          oderId: user.id,
          email: user.email,
          corpId: user.corpId,
          password: event.password,
        );

        // Lock device to this user on first login
        await _storageService.lockDeviceToUser(user.id, user.name);

        // Mark first login as completed
        await _storageService.setFirstLoginCompleted();

        emit(await _getFullAuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));
      } else {
        emit(const AuthState.error('Login failed'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthBiometricLoginRequested(
    AuthBiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      final biometricEnabled = await _storageService.getBiometricEnabled();
      if (!biometricEnabled) {
        emit(const AuthState.error('Device authentication not enabled'));
        return;
      }

      final authResult = await _biometricService.smartAuthenticate(
        reason: 'Authenticate to login',
      );

      if (authResult.success) {
        // Get stored credentials and re-authenticate with Firebase
        final credentials = await _storageService.getSavedCredentials();
        final email = credentials['email'];
        final password = credentials['password'];
        final corpId = credentials['corpId'];
        
        if (email == null || password == null || corpId == null) {
          emit(const AuthState.error('Saved credentials not found. Please login with your credentials.'));
          return;
        }
        
        final user = await _authService.signInWithEmailPassword(
          email: email,
          password: password,
          corpId: corpId,
        );
        
        if (user != null) {
          emit(await _getFullAuthState(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(const AuthState.error('Authentication failed. Please login with credentials.'));
        }
      } else {
        emit(AuthState.error(authResult.message));
      }
    } on BiometricException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthFaceIdLoginRequested(
    AuthFaceIdLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      final faceIdEnabled = await _storageService.getFaceIdEnabled();
      if (!faceIdEnabled) {
        emit(const AuthState.error('Face ID authentication not enabled'));
        return;
      }

      // Use authenticateWithFace which properly handles Android face unlock
      final authResult = await _biometricService.authenticateWithFace(
        reason: 'Look at your device to login with face',
      );

      if (authResult) {
        // Get stored credentials and re-authenticate with Firebase
        final credentials = await _storageService.getSavedCredentials();
        final email = credentials['email'];
        final password = credentials['password'];
        final corpId = credentials['corpId'];
        
        if (email == null || password == null || corpId == null) {
          emit(const AuthState.error('Saved credentials not found. Please login with your credentials.'));
          return;
        }
        
        final user = await _authService.signInWithEmailPassword(
          email: email,
          password: password,
          corpId: corpId,
        );
        
        if (user != null) {
          emit(await _getFullAuthState(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(const AuthState.error('Authentication failed. Please login with credentials.'));
        }
      } else {
        emit(const AuthState.error('Face authentication failed'));
      }
    } on BiometricException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthFingerprintLoginRequested(
    AuthFingerprintLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      final fingerprintEnabled = await _storageService.getFingerprintEnabled();
      if (!fingerprintEnabled) {
        emit(const AuthState.error('Fingerprint authentication not enabled'));
        return;
      }

      final authResult = await _biometricService.authenticate(
        reason: 'Authenticate with fingerprint to login',
        allowDeviceCredential: false,
      );

      if (authResult) {
        // Get stored credentials and re-authenticate with Firebase
        final credentials = await _storageService.getSavedCredentials();
        final email = credentials['email'];
        final password = credentials['password'];
        final corpId = credentials['corpId'];
        
        if (email == null || password == null || corpId == null) {
          emit(const AuthState.error('Saved credentials not found. Please login with your credentials.'));
          return;
        }
        
        final user = await _authService.signInWithEmailPassword(
          email: email,
          password: password,
          corpId: corpId,
        );
        
        if (user != null) {
          emit(await _getFullAuthState(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(const AuthState.error('Authentication failed. Please login with credentials.'));
        }
      } else {
        emit(const AuthState.error('Fingerprint authentication failed'));
      }
    } on BiometricException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthPinPatternLoginRequested(
    AuthPinPatternLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      final pinPatternEnabled = await _storageService.getPinPatternEnabled();
      if (!pinPatternEnabled) {
        emit(const AuthState.error('PIN/Pattern authentication not enabled'));
        return;
      }

      final authResult = await _biometricService.authenticateWithDeviceCredential(
        reason: 'Enter your PIN, pattern, or password to login',
      );

      if (authResult) {
        // Get stored credentials and re-authenticate with Firebase
        final credentials = await _storageService.getSavedCredentials();
        final email = credentials['email'];
        final password = credentials['password'];
        final corpId = credentials['corpId'];
        
        if (email == null || password == null || corpId == null) {
          emit(const AuthState.error('Saved credentials not found. Please login with your credentials.'));
          return;
        }
        
        final user = await _authService.signInWithEmailPassword(
          email: email,
          password: password,
          corpId: corpId,
        );
        
        if (user != null) {
          emit(await _getFullAuthState(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(const AuthState.error('Authentication failed. Please login with credentials.'));
        }
      } else {
        emit(const AuthState.error('PIN/Pattern authentication failed'));
      }
    } on BiometricException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthQuickLoginRequested(
    AuthQuickLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      // Check if any quick login is enabled
      final anyEnabled = await _storageService.isAnyQuickLoginEnabled();
      if (!anyEnabled) {
        emit(const AuthState.error('No quick login method enabled'));
        return;
      }

      // Use smart authenticate which will use the best available method
      final authResult = await _biometricService.smartAuthenticate(
        reason: 'Authenticate to login',
      );

      if (authResult.success) {
        // Get stored credentials and re-authenticate with Firebase
        final credentials = await _storageService.getSavedCredentials();
        final email = credentials['email'];
        final password = credentials['password'];
        final corpId = credentials['corpId'];
        
        if (email == null || password == null || corpId == null) {
          emit(const AuthState.error('Saved credentials not found. Please login with your credentials.'));
          return;
        }
        
        final user = await _authService.signInWithEmailPassword(
          email: email,
          password: password,
          corpId: corpId,
        );
        
        if (user != null) {
          emit(await _getFullAuthState(
            status: AuthStatus.authenticated,
            user: user,
          ));
        } else {
          emit(const AuthState.error('Authentication failed. Please login with credentials.'));
        }
      } else {
        emit(AuthState.error(authResult.message));
      }
    } on BiometricException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      // Check if device is locked to another user
      final isLocked = await _storageService.isDeviceLockedToUser();
      if (isLocked) {
        final lockedUserName = await _storageService.getLockedUserName();
        emit(AuthState.error(
          'This device is registered to $lockedUserName. '
          'To use a different account, please clear app data or reinstall the app.',
        ));
        return;
      }

      final user = await _authService.registerUser(
        name: event.name,
        email: event.email,
        password: event.password,
        companyId: event.companyId,
        companyName: event.companyName,
        corpId: event.corpId,
        isAdmin: event.isAdmin,
        isSupervisor: event.isSupervisor,
        supervisorId: event.supervisorId,
      );

      if (user != null) {
        await _storageService.saveUserCredentials(
          oderId: user.id,
          email: user.email,
          corpId: user.corpId,
          password: event.password,
        );

        // Lock device to this user
        await _storageService.lockDeviceToUser(user.id, user.name);
        await _storageService.setFirstLoginCompleted();

        emit(await _getFullAuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));
      } else {
        emit(const AuthState.error('Registration failed'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthEnableBiometric(
    AuthEnableBiometric event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (event.enable) {
        final authResult = await _biometricService.smartAuthenticate(
          reason: 'Authenticate to enable device security login',
        );

        if (authResult.success) {
          await _storageService.saveBiometricEnabled(true);
          await _authService.updateBiometricStatus(true);

          emit(state.copyWith(
            biometricEnabled: true,
            status: AuthStatus.authenticated,
          ));
        }
      } else {
        await _storageService.saveBiometricEnabled(false);
        await _authService.updateBiometricStatus(false);

        emit(state.copyWith(
          biometricEnabled: false,
          status: AuthStatus.authenticated,
        ));
      }
    } on BiometricException catch (e) {
      print('BiometricException: ${e.message}');
    } catch (e) {
      print('Error enabling biometric: $e');
    }
  }

  Future<void> _onAuthEnableFaceId(
    AuthEnableFaceId event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (event.enable) {
        // Use face-specific authentication to enable Face ID
        final authResult = await _biometricService.authenticateWithFace(
          reason: 'Look at your device to enable Face Login',
        );

        if (authResult) {
          await _storageService.saveFaceIdEnabled(true);
          await _storageService.saveBiometricEnabled(true);
          await _authService.updateBiometricStatus(true);

          emit(state.copyWith(
            faceIdEnabled: true,
            biometricEnabled: true,
            status: AuthStatus.authenticated,
          ));
        }
      } else {
        await _storageService.saveFaceIdEnabled(false);
        
        final fingerprintEnabled = await _storageService.getFingerprintEnabled();
        final pinPatternEnabled = await _storageService.getPinPatternEnabled();
        final anyEnabled = fingerprintEnabled || pinPatternEnabled;
        
        if (!anyEnabled) {
          await _storageService.saveBiometricEnabled(false);
          await _authService.updateBiometricStatus(false);
        }

        emit(state.copyWith(
          faceIdEnabled: false,
          biometricEnabled: anyEnabled,
          status: AuthStatus.authenticated,
        ));
      }
    } on BiometricException catch (e) {
      print('BiometricException: ${e.message}');
    } catch (e) {
      print('Error enabling Face ID: $e');
    }
  }

  Future<void> _onAuthEnableFingerprint(
    AuthEnableFingerprint event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (event.enable) {
        final authResult = await _biometricService.authenticate(
          reason: 'Authenticate to enable Fingerprint login',
          allowDeviceCredential: true,
        );

        if (authResult) {
          await _storageService.saveFingerprintEnabled(true);
          await _storageService.saveBiometricEnabled(true);
          await _authService.updateBiometricStatus(true);

          emit(state.copyWith(
            fingerprintEnabled: true,
            biometricEnabled: true,
            status: AuthStatus.authenticated,
          ));
        }
      } else {
        await _storageService.saveFingerprintEnabled(false);
        
        final faceIdEnabled = await _storageService.getFaceIdEnabled();
        final pinPatternEnabled = await _storageService.getPinPatternEnabled();
        final anyEnabled = faceIdEnabled || pinPatternEnabled;
        
        if (!anyEnabled) {
          await _storageService.saveBiometricEnabled(false);
          await _authService.updateBiometricStatus(false);
        }

        emit(state.copyWith(
          fingerprintEnabled: false,
          biometricEnabled: anyEnabled,
          status: AuthStatus.authenticated,
        ));
      }
    } on BiometricException catch (e) {
      print('BiometricException: ${e.message}');
    } catch (e) {
      print('Error enabling Fingerprint: $e');
    }
  }

  Future<void> _onAuthEnablePinPattern(
    AuthEnablePinPattern event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (event.enable) {
        final authResult = await _biometricService.authenticateWithDeviceCredential(
          reason: 'Enter your PIN/Pattern to enable quick login',
        );

        if (authResult) {
          await _storageService.savePinPatternEnabled(true);
          await _storageService.saveBiometricEnabled(true);
          await _authService.updateBiometricStatus(true);

          emit(state.copyWith(
            pinPatternEnabled: true,
            biometricEnabled: true,
            status: AuthStatus.authenticated,
          ));
        }
      } else {
        await _storageService.savePinPatternEnabled(false);
        
        final faceIdEnabled = await _storageService.getFaceIdEnabled();
        final fingerprintEnabled = await _storageService.getFingerprintEnabled();
        final anyEnabled = faceIdEnabled || fingerprintEnabled;
        
        if (!anyEnabled) {
          await _storageService.saveBiometricEnabled(false);
          await _authService.updateBiometricStatus(false);
        }

        emit(state.copyWith(
          pinPatternEnabled: false,
          biometricEnabled: anyEnabled,
          status: AuthStatus.authenticated,
        ));
      }
    } on BiometricException catch (e) {
      print('BiometricException: ${e.message}');
    } catch (e) {
      print('Error enabling PIN/Pattern: $e');
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.signOut();
      // Don't clear biometric settings or device lock on logout
      emit(await _getFullAuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthUpdateProfileImage(
    AuthUpdateProfileImage event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.updateProfileImage(event.imagePath);

      if (state.user != null) {
        emit(state.copyWith(
          user: state.user!.copyWith(profileImagePath: event.imagePath),
        ));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onAuthRefreshUser(
    AuthRefreshUser event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        emit(state.copyWith(user: user));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }
}
