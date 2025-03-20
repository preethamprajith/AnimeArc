import 'package:flutter/material.dart';
import 'package:user/screens/account.dart';
import 'package:user/screens/browse.dart';
import 'package:user/screens/mylist.dart';
import 'package:user/screens/store.dart';
import 'package:user/screens/userhome.dart';
import 'package:google_fonts/google_fonts.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  final List<Widget> items = [
    const Userhome(),
    const MyList(),
    const Store(),
    const Browse(),
    const Account(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: items[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1.0)),
          color: Colors.black87,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent, // Transparent for container background
          selectedItemColor: Colors.orange, // Selected icon color
          unselectedItemColor: Colors.grey[600], // Unselected icon color
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_outlined),
              activeIcon: const Icon(Icons.list),
              label: 'My List',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.store_outlined),
              activeIcon: const Icon(Icons.store),
              label: 'Store',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_outlined),
              activeIcon: const Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
          selectedLabelStyle: GoogleFonts.poppins(
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            textStyle: const TextStyle(fontSize: 12),
          ),
          iconSize: 24,
          elevation: 0,
        ),
      ),
    );
  }
}