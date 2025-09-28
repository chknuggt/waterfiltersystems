import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
    } catch (e) {
      throw 'Firebase is not configured. Please run "flutterfire configure" to set up Firebase.';
    }
  }

  // Get current user
  User? get currentUser => _auth?.currentUser;

  // Get current user with Firebase initialization
  Future<User?> getCurrentUser() async {
    await _ensureInitialized();
    return _auth?.currentUser;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges async* {
    try {
      await _ensureInitialized();
      yield* _auth!.authStateChanges();
    } catch (e) {
      // If Firebase is not configured, yield null (no user)
      yield null;
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.user,
  }) async {
    await _ensureInitialized();

    try {
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user model
        final UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          role: role,
        );

        // Save user to Firestore
        await _firestore!.collection('users').doc(userCredential.user!.uid).set(newUser.toMap());

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
    return null;
  }

  // Create admin user
  Future<UserModel?> createAdminUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
      role: UserRole.admin,
    );
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update last login time in Firestore
        await _firestore!.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
        });

        // Get user data from Firestore
        final DocumentSnapshot userDoc = await _firestore!
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
    return null;
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    await _ensureInitialized();

    try {
      final DocumentSnapshot userDoc = await _firestore!
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _ensureInitialized();

    try {
      await _auth!.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _ensureInitialized();

    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    await _ensureInitialized();

    try {
      final user = _auth!.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore!.collection('users').doc(user.uid).delete();
        // Delete user from Firebase Auth
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Check if current user is admin using custom claims
  Future<bool> isCurrentUserAdmin() async {
    try {
      await _ensureInitialized();
      final user = await getCurrentUser();
      if (user != null) {
        print('Checking admin status for user: ${user.email}');
        final idTokenResult = await user.getIdTokenResult();
        print('Token issued at: ${idTokenResult.issuedAtTime}');
        print('Token auth time: ${idTokenResult.authTime}');
        print('All claims: ${idTokenResult.claims}');

        final role = idTokenResult.claims?['role'];
        print('Role claim value: $role');

        final isAdmin = role == 'admin';
        print('Is admin result: $isAdmin');
        return isAdmin;
      } else {
        print('No current user found');
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
    return false;
  }

  // Get user's company from custom claims
  Future<String?> getUserCompany() async {
    try {
      await _ensureInitialized();
      final user = await getCurrentUser();
      if (user != null) {
        final idTokenResult = await user.getIdTokenResult();
        final company = idTokenResult.claims?['company'];
        print('Company claim: $company');
        return company;
      }
    } catch (e) {
      print('Error getting user company: $e');
    }
    return null;
  }

  // Debug method to print all claims
  Future<void> debugPrintAllClaims() async {
    try {
      await _ensureInitialized();
      final user = await getCurrentUser();
      if (user != null) {
        print('=== DEBUG: Current User Claims ===');
        print('User email: ${user.email}');
        print('User UID: ${user.uid}');
        print('Email verified: ${user.emailVerified}');

        final idTokenResult = await user.getIdTokenResult();
        print('Token issued at: ${idTokenResult.issuedAtTime}');
        print('Token expires at: ${idTokenResult.expirationTime}');
        print('Token auth time: ${idTokenResult.authTime}');
        print('All custom claims:');

        if (idTokenResult.claims?.isEmpty ?? true) {
          print('  No custom claims found!');
        } else {
          idTokenResult.claims?.forEach((key, value) {
            print('  $key: $value');
          });
        }
        print('=== END DEBUG ===');
      } else {
        print('=== DEBUG: No current user ===');
      }
    } catch (e) {
      print('Error debugging claims: $e');
    }
  }

  // Update email address with reauthentication
  Future<void> updateUserEmail(String newEmail, String currentPassword) async {
    await _ensureInitialized();

    final user = currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      // Reauthenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email (this sends verification email automatically)
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update in Firestore
      await _firestore!.collection('users').doc(user.uid).update({
        'email': newEmail,
      });

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update email. Please try again.';
    }
  }

  // Update password with reauthentication
  Future<void> updateUserPassword(String currentPassword, String newPassword) async {
    await _ensureInitialized();

    final user = currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      // Reauthenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update password. Please try again.';
    }
  }

  // Force refresh ID token to get latest custom claims
  Future<void> refreshUserToken() async {
    try {
      await _ensureInitialized();
      final user = await getCurrentUser();
      if (user != null) {
        print('Refreshing token for user: ${user.email}');
        final oldToken = await user.getIdToken(false);
        print('Old token (first 50 chars): ${oldToken?.substring(0, 50) ?? 'null'}...');

        final newToken = await user.getIdToken(true); // Force refresh
        print('New token (first 50 chars): ${newToken?.substring(0, 50) ?? 'null'}...');
        print('Token refreshed successfully');

        // Get the new claims
        final idTokenResult = await user.getIdTokenResult(true);
        print('New claims after refresh: ${idTokenResult.claims}');
      } else {
        print('No user to refresh token for');
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
  }
}