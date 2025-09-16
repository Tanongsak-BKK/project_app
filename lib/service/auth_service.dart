import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );

    // อัปเดต displayName ในโปรไฟล์ Firebase Auth
    await cred.user?.updateDisplayName(displayName);

    // สร้างเอกสาร users/{uid} ใน Firestore ถ้ายังไม่มี
    final doc = _db.collection('users').doc(cred.user!.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'uid': cred.user!.uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': cred.user?.photoURL,
        'provider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
      });
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // มีแล้วข้ามได้: Google sign-in (ที่ให้ไว้ก่อนหน้า)
  // Future<UserCredential> signInWithGoogle() { ... }
  Future<UserCredential> signInWithGoogle() async {
  if (kIsWeb) {
    final provider = GoogleAuthProvider();
    final cred = await _auth.signInWithPopup(provider);
    await _ensureUserDoc(cred.user);              // ✅ สร้าง/อัปเดต users/{uid}
    return cred;
  } else {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'aborted-by-user', message: 'Canceled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    await _ensureUserDoc(cred.user);              // ✅ สำคัญ!
    return cred;
  }
}

Future<void> _ensureUserDoc(User? user) async {
  if (user == null) return;
  final ref = _db.collection('users').doc(user.uid);
  await ref.set({
    'uid': user.uid,
    'email': user.email,
    'displayName': user.displayName ?? user.email?.split('@').first ?? 'User',
    'photoUrl': user.photoURL,
    'provider': 'google',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

}
