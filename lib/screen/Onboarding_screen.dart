import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:project_app/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final List<PageViewModel> pages = [
    
    PageViewModel(
      titleWidget: const SizedBox.shrink(), // ไม่ใช้ title ปกติ
      bodyWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center, // จัดกลางจอ
        children: [
          // รูปเลื่อนลงมากลางจอ
          const SizedBox(height: 180),
          Image.asset(
            "lib/images/mountain.png",
            height: 300,
          ),
          const SizedBox(height: 20), // เว้นระยะ
          const Text(
            "Welcome to Tarvel App",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Discover new places and plan your trips with ease.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
       
            PageViewModel(
      titleWidget: const SizedBox.shrink(), // ไม่ใช้ title ปกติ
      bodyWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center, // จัดกลางจอ
        children: [
          // รูปเลื่อนลงมากลางจอ
          const SizedBox(height: 180),
          Image.asset(
            "lib/images/maps.png",
            height: 300,
          ),
          const SizedBox(height: 20), // เว้นระยะ
          const Text(
            "point hiking",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hiking spots and mountains in Thailand.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),


    PageViewModel(
      titleWidget: const SizedBox.shrink(), // ไม่ใช้ title ปกติ
      bodyWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center, // จัดกลางจอ
        children: [
          // รูปเลื่อนลงมากลางจอ
          const SizedBox(height: 180),
          Image.asset(
            "lib/images/humans.png",
            height: 300,
          ),
          const SizedBox(height: 80), // เว้นระยะ
          const Text(
            "Ready to pack your bags",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Pack your bags and go into nature.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ];

  Future<void> _finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    // ไปหน้า Login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:  BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/images/background-onboarding.jpg"),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
          gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 0, 71, 154),
                  Color.fromARGB(255, 3, 136, 154),
                  Color.fromARGB(255, 19, 238, 154),
                ],
                stops: [0.1, 0.4, 0.8],
              ),
        ),
        child: IntroductionScreen(
          globalBackgroundColor: const Color.fromARGB(0, 255, 255, 255), // สำคัญมาก!
          pages: pages,
          onDone: () {
            // TODO: ไปหน้า LoginScreen หรือ MainApp
            _finishOnboarding(context);
          },
          showSkipButton: true,
          skip:  Text("Skip", style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
          next:  Icon(Icons.arrow_forward, color: Colors.white,),
          done:  Text("Done",
              style: TextStyle(fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255))),
          dotsDecorator: const DotsDecorator(
            color: Color.fromARGB(137, 0, 0, 0),
            size: Size(10, 10),
            activeSize: Size(15, 10),
            activeColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
    );
  }
}
