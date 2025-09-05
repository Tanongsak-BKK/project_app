import 'package:flutter/material.dart';
import 'package:project_app/screen/login_screen.dart';
import 'package:project_app/screen/signup_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class NavbarScreen extends StatefulWidget {
  const NavbarScreen({super.key});

  @override
  State<NavbarScreen> createState() => _NavbarScreenState();
}

class _NavbarScreenState extends State<NavbarScreen> {
  int _selectedIndex = 0;

  // ใช้ IndexedStack เพื่อคง state ของแต่ละหน้า
  final List<Widget> _pages = const [
    LoginScreen(),
    SignupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
    child:SafeArea(
      top: false,
      left: false,
      right: false,
    
    child:Scaffold(
      // selectedIndex: _selectedIndex,
      body: _pages[_selectedIndex],
      // navigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(255, 19, 238, 154),
        
        /*onTap: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },*/
        
        items:   [
        Icon(Icons.payment, size: 30),
        Icon(Icons.search, size: 30),
        Icon(Icons.home_outlined, size: 30),
        Icon(Icons.person, size: 30),
        Icon(Icons.settings, size: 30),
      ],
    ),
    ),
    ),
    );
  }
}
