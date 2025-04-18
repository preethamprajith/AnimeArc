import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/screens/account.dart';
import 'package:user/screens/mylist.dart';
import 'package:user/screens/store.dart';
import 'package:user/screens/userhome.dart';
import 'package:user/main.dart'; // Import for AnimeTheme

class Dashboard extends StatefulWidget {
  final int selectedIndex; // Allow selecting an initial tab

  const Dashboard({super.key, this.selectedIndex = 0}); // Default is Home

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const Userhome(),
    const MyList(),
    const Store(),
    const Account(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex; // Initialize with passed index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AnimeTheme.primaryPurple,
                  AnimeTheme.darkPurple,
                ],
              ),
            ),
          ),
          // Screen content
          _screens[_selectedIndex], // Display the selected page
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D0A4D), // Darker purple
              Color(0xFF230838), // Even darker shade
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AnimeTheme.accentPink,
          unselectedItemColor: Colors.grey[400],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index; // Update selected tab
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
              icon: const Icon(Icons.account_circle_outlined),
              activeIcon: const Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
          selectedLabelStyle: GoogleFonts.poppins(
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            textStyle: const TextStyle(fontSize: 11),
          ),
          iconSize: 24,
          elevation: 0,
        ),
      ),
    );
  }
}
