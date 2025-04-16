import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/screens/account.dart';
import 'package:user/screens/browse.dart';
import 'package:user/screens/mylist.dart';
import 'package:user/screens/store.dart';
import 'package:user/screens/userhome.dart';

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
    const Browse(),
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
      body: _screens[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black87,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[600],
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
    );
  }
}
