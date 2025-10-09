import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:device_preview_plus/device_preview_plus.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:project_app/provider/place_provider.dart';
import 'AuthGate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ทำให้จอแสดงผลเต็ม (edge-to-edge) + status bar โปร่งใส
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(0, 0, 0, 0),
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark,      // iOS
  ));

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
    // ✅ fallback ตรวจด้วย try-catch
    bool hasUseInheritedMediaQuery = false;
    try {
      // ถ้า property นี้มีใน MaterialApp → จะไม่ throw
      MaterialApp(useInheritedMediaQuery: true);
      hasUseInheritedMediaQuery = true;
    } catch (_) {
      hasUseInheritedMediaQuery = false;
    }

    if (hasUseInheritedMediaQuery) {
      // ---------------------------
      // Flutter SDK ใหม่ (>=2.10)
      // ---------------------------
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        builder: DevicePreview.appBuilder,
        locale: DevicePreview.locale(context),
        title: 'Travel App',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2F80ED),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
        ),
        home: const AuthGate(),
      );
    } else {
      // ---------------------------
      // Flutter SDK เก่า (<2.10)
      // ---------------------------
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return DevicePreview.appBuilder(context, child);
        },
        locale: DevicePreview.locale(context),
        title: 'Travel App',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2F80ED),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
        ),
        home: const AuthGate(),
      );
    }
  }
}
