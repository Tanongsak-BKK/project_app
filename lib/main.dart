
import 'package:flutter/material.dart';
import 'package:project_app/screen/Onboarding_screen.dart';
import 'package:project_app/screen/login_screen.dart';
import 'package:project_app/screen/navbar_screen.dart';
import 'package:project_app/screen/signup_screen.dart';
import 'package:project_app/screen/home_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: const Color.fromARGB(255, 19, 220, 238),
      debugShowCheckedModeBanner: false,
      title: 'Flutter demo app.',
      home: NavbarScreen(),
    );
  }
}
