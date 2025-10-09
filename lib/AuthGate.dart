// lib/AuthGate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen/navbar_screen.dart';     // ใช้ของเดิมคุณ
import 'screen/login_screen.dart';      // หน้า Login เดิมคุณ (เดี๋ยวผมผูกปุ่มให้)

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          return const LoginScreen();     // ยังไม่ล็อกอิน -> ไปหน้า Login เดิม
        }
        return const NavbarScreen();      // ล็อกอินแล้ว -> เข้าแอปตามเดิม
      },
    );
  }
}
