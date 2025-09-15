import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/place_provider.dart';
import 'screen/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlaceProvider()..loadPlaces(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false, // << ปิดแถบ DEBUG
  title: 'Travel App',
  theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2F80ED)),
  home: const HomeScreen(),
);

  }
}
