import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animearc_admin/screens/login.dart';

class SideBar extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const SideBar(
      {super.key, required this.onItemSelected, required this.selectedIndex});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final List<String> pages = [
    "DASHBOARD",
    "MANAGE CATEGORY",
    "MANAGE ANIME",
    "MANAGE GENRE",
    "MANAGE PRODUCT",
    "VIEW PRODUCT",
    "MANAGE BOOKING",
    "MANAGE MANGA",
    "VIEWS AND REVIEW COMPLAINT",
  ];

  final List<IconData> icons = [
    Icons.dashboard_rounded,
    Icons.category_rounded,
    Icons.movie_rounded,
    Icons.style_rounded,
    Icons.production_quantity_limits_rounded,
    Icons.visibility_rounded,
    Icons.store_rounded,
    Icons.book_online_rounded,
    Icons.feedback_rounded,
  ];

  Future<void> _handleLogout(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8A2BE2),
        ),
      ),
    );

    try {
      // Sign out from Supabase
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut();
      
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Navigate to login page
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginPage()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, // Sidebar width
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
  
          // Logo and Title
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    "assets/123.png",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFFB975FF),
                        Color(0xFF8A2BE2),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'ANIME HUB',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
  
          const SizedBox(height: 30),
          
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: Colors.white.withOpacity(0.1),
              thickness: 1,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Menu label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
  
          // Sidebar Menu Items
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                bool isSelected = widget.selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF8A2BE2),
                              Color(0xFF5D1E9E),
                            ],
                          )
                        : null,
                      color: isSelected
                          ? null
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      onTap: () {
                        widget.onItemSelected(index);
                      },
                      leading: Icon(
                        icons[index],
                        color:
                            isSelected ? Colors.white : const Color(0xFF8A2BE2),
                        size: 22,
                      ),
                      title: Text(
                        pages[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom section - Logout button
          InkWell(
            onTap: () => _handleLogout(context),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LOGOUT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
