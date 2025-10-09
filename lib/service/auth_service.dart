// lib/service/auth_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- Email/Password ----------------
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ---------------- Google ----------------
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      return await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'User cancelled Google sign-in',
        );
      }
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(cred);
    }
  }

  // ---------------- GitHub ----------------
  Future<UserCredential> signInWithGithub() async {
    final provider = OAuthProvider('github.com')
      ..addScope('read:user')
      ..addScope('user:email');

    if (kIsWeb) {
      // Web ใช้ popup ได้เลย
      return await _auth.signInWithPopup(provider);
    } else {
      // Android/iOS ใช้ signInWithProvider (SDK จะเปิดเบราว์เซอร์ให้อัตโนมัติ)
      return await _auth.signInWithProvider(provider);
    }
  }

  // ---------------- Sign out ----------------
  Future<void> signOut() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try { await GoogleSignIn().signOut(); } catch (_) {}
    }
    await _auth.signOut();
  }
}
