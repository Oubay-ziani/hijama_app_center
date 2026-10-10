import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final User? firebaseUser;

  AuthState({this.isLoading = false, this.errorMessage, this.firebaseUser});

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? firebaseUser,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      firebaseUser: firebaseUser ?? this.firebaseUser,
    );
  }

  // Convenience helpers used across the app
  Map<String, dynamic>? get user => firebaseUser != null
      ? {
          'uid': firebaseUser!.uid,
          'email': firebaseUser!.email,
          'name': firebaseUser!.displayName ?? firebaseUser!.email,
          'role': 'admin', // default; update from Firestore if needed
        }
      : null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
          firebaseUser: FirebaseAuth.instance.currentUser,
        ));

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  bool get isAuthenticated => state.firebaseUser != null;
  String? get role => 'admin'; // extend with Firestore role doc if needed
  String? get name =>
      state.firebaseUser?.displayName ?? state.firebaseUser?.email;

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = AuthState(firebaseUser: credential.user);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<bool> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name);

      // Store user profile in Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': name,
        'email': email.trim(),
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = AuthState(firebaseUser: credential.user);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);

      // Upsert profile
      final docRef =
          _firestore.collection('users').doc(userCred.user!.uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'name': userCred.user!.displayName,
          'email': userCred.user!.email,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      state = AuthState(firebaseUser: userCred.user);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    state = AuthState(); // firebaseUser defaults to null → user is logged out
  }

  // ── Change Password ────────────────────────────────────────────────────────
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed. ($code)';
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
