// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:alzeh/core/services/firestore_service.dart';
import 'package:alzeh/features/model/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // ==================== EMAIL/PASSWORD AUTH ====================

  /// Sign up with email and password
  static Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user profile in Firestore
        final userModel = UserModel(
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          disease: '',
          profileImageUrl: null,
        );

        await FirestoreService.saveUserProfile(userModel);

        return AuthResult(
          success: true,
          user: credential.user,
          message: 'Account created successfully',
        );
      }

      return AuthResult(
        success: false,
        message: 'Failed to create account',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Sign in with email and password
  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return AuthResult(
        success: true,
        user: credential.user,
        message: 'Signed in successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // ==================== GOOGLE SIGN IN ====================

  /// Sign in with Google
  static Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult(
          success: false,
          message: 'Sign in cancelled',
        );
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if new user and create profile
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final userModel = UserModel(
          name: userCredential.user?.displayName ?? 'User',
          email: userCredential.user?.email ?? '',
          phoneNumber: userCredential.user?.phoneNumber ?? '',
          disease: '',
          profileImageUrl: userCredential.user?.photoURL,
        );

        await FirestoreService.saveUserProfile(userModel);
      }

      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Signed in with Google successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to sign in with Google: $e',
      );
    }
  }

  // ==================== FACEBOOK SIGN IN ====================

  /// Sign in with Facebook
  static Future<AuthResult> signInWithFacebook() async {
    try {
      // Trigger Facebook Sign In
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        return AuthResult(
          success: false,
          message: 'Facebook sign in cancelled or failed',
        );
      }

      // Create credential
      final OAuthCredential credential =
      FacebookAuthProvider.credential(result.accessToken!.tokenString);

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if new user and create profile
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final userModel = UserModel(
          name: userCredential.user?.displayName ?? 'User',
          email: userCredential.user?.email ?? '',
          phoneNumber: userCredential.user?.phoneNumber ?? '',
          disease: '',
          profileImageUrl: userCredential.user?.photoURL,
        );

        await FirestoreService.saveUserProfile(userModel);
      }

      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Signed in with Facebook successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to sign in with Facebook: $e',
      );
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Send password reset email
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: 'Password reset email sent',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to send reset email: $e',
      );
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out from all providers
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // ==================== ACCOUNT MANAGEMENT ====================

  /// Update user profile
  static Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Delete user account
  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      await user.delete();
      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to delete account: $e',
      );
    }
  }

  // ==================== HELPER METHODS ====================

  /// Convert Firebase error codes to user-friendly messages
  static String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'account-exists-with-different-credential':
        return 'Account exists with different sign-in method';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed: $code';
    }
  }
}

// ==================== AUTH RESULT CLASS ====================

class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
  });
}