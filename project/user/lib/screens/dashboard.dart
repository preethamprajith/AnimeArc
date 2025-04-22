import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/screens/account.dart';
import 'package:user/screens/mylist.dart';
import 'package:user/screens/store.dart';
import 'package:user/screens/userhome.dart';
import 'package:user/theme/anime_theme.dart'; // Import for AnimeTheme

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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AnimeTheme.darkPurple.withOpacity(0.95),
              AnimeTheme.darkPurple,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.list_outlined, Icons.list, 'My List'),
                _buildNavItem(2, Icons.store_outlined, Icons.store, 'Store'),
                _buildNavItem(3, Icons.account_circle_outlined, Icons.account_circle, 'Account'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: AnimeTheme.defaultDuration,
        curve: AnimeTheme.defaultCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AnimeTheme.accentGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
