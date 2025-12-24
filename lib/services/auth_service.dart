import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmailPassword({
    required String email,
    required String password,
    required String corpId,
  }) async {
    try {
      // Sign in with email and password
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Verify corpId matches
        final userSnapshot = await _database
            .ref('users/${credential.user!.uid}')
            .get();

        if (userSnapshot.exists) {
          final userData = UserModel.fromRealtimeDB(
            credential.user!.uid,
            Map<String, dynamic>.from(userSnapshot.value as Map),
          );
          if (userData.corpId == corpId) {
            return userData;
          } else {
            await _auth.signOut();
            throw Exception('Invalid Corp ID for this user');
          }
        } else {
          throw Exception('User data not found');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    }
  }

  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String password,
    required String companyId,
    required String companyName,
    required String corpId,
    required bool isAdmin,
    required bool isSupervisor,
    String? supervisorId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          corpId: corpId,
          companyId: companyId,
          companyName: companyName,
          isAdmin: isAdmin,
          isSupervisor: isSupervisor,
          supervisorId: supervisorId,
          biometricEnabled: false,
          createdAt: DateTime.now(),
        );

        await _database
            .ref('users/${credential.user!.uid}')
            .set(user.toRealtimeDB());

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser != null) {
        final userSnapshot = await _database
            .ref('users/${currentUser!.uid}')
            .get();

        if (userSnapshot.exists) {
          return UserModel.fromRealtimeDB(
            currentUser!.uid,
            Map<String, dynamic>.from(userSnapshot.value as Map),
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Future<void> updateBiometricStatus(bool enabled) async {
    try {
      if (currentUser != null) {
        await _database.ref('users/${currentUser!.uid}').update({
          'biometricEnabled': enabled,
          'updatedAt': ServerValue.timestamp,
        });
      }
    } catch (e) {
      throw Exception('Failed to update biometric status: $e');
    }
  }

  Future<void> updateProfileImage(String imagePath) async {
    try {
      if (currentUser != null) {
        await _database.ref('users/${currentUser!.uid}').update({
          'profileImagePath': imagePath,
          'updatedAt': ServerValue.timestamp,
        });
      }
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  Future<List<UserModel>> getSubordinates(String supervisorId) async {
    try {
      final snapshot = await _database
          .ref('users')
          .orderByChild('supervisorId')
          .equalTo(supervisorId)
          .get();

      if (snapshot.exists) {
        final List<UserModel> subordinates = [];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          subordinates.add(UserModel.fromRealtimeDB(
            key,
            Map<String, dynamic>.from(value),
          ));
        });
        return subordinates;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get subordinates: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Password reset failed');
    }
  }
}
