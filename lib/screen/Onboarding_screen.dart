import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:project_app/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final List<PageViewModel> pages = [
    PageViewModel(
      title: "Welcome to MyApp",
      body: "This is a simple app to demonstrate onboarding screens.",
       image: Align(
        alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          "lib/gifs/backpack.gif",
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    ),

    ),
    PageViewModel(
      title: "Stay Organized",
      body: "Keep track of your tasks and stay organized with our app.",
      image: Center(child: Image.asset("assets/images/onboarding2.png", height: 175)),
    ),
    PageViewModel(
      title: "Get Started",
      body: "Let's get started! Sign up or log in to continue.",
      image: Center(child: Image.asset("assets/images/onboarding3.png", height: 175)),
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
