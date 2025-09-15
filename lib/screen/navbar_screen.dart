import 'package:flutter/material.dart';
import 'package:project_app/screen/home_screen.dart';
import 'package:project_app/screen/map_screen_vector.dart';
import 'package:project_app/screen/profile_screen.dart';
import 'package:project_app/screen/listuserlocation_screen.dart';

class NavbarScreen extends StatefulWidget {
  const NavbarScreen({super.key});

  @override
  State<NavbarScreen> createState() => _NavbarScreenState();
}

class _NavbarScreenState extends State<NavbarScreen> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    MapScreenVector(),
    ListUserLocationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _BottomPillNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomPillNav extends StatelessWidget {
  const _BottomPillNav({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                icon: Icons.home_filled,
                active: index == 0,
                onTap: () => onChanged(0),
              ),
              _NavIcon(
                icon: Icons.grid_view_rounded,
                active: index == 1,
                onTap: () => onChanged(1),
              ),
              _NavIcon(
                icon: Icons.favorite_border,
                active: index == 2,
                onTap: () => onChanged(2),
              ),
              _NavIcon(
                icon: Icons.person,
                active: index == 3,
                onTap: () => onChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.active, required this.onTap});
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Icon(
        icon,
        color: active ? Colors.white : Colors.white70,
        size: 26,
      ),
    );
  }
}


