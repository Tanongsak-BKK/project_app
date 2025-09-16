// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ต้องมีไฟล์นี้จาก flutterfire configure

import 'package:project_app/provider/place_provider.dart';
import 'AuthGate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ต้อง init Firebase ก่อนใช้ AuthGate/FirebaseAuth ทุกครั้ง (สำคัญมากโดยเฉพาะบน Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => PlaceProvider()..loadPlaces(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),
      title: 'Travel App',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2F80ED)),
      home: const AuthGate(), // ใช้ AuthGate ได้เพราะ init Firebase แล้ว
    );
  }
}
