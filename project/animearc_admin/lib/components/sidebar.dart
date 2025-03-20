import 'package:animearc_admin/screens/login.dart';
import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const SideBar({super.key, required this.onItemSelected, required this.selectedIndex});

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
    "MANAGE STOCK",
    "MANAGE BOOKING",
    "MANAGE ANIMEFILE",
    "VIEWS AND REVIEW COMPLAINT",
    
  ];

  final List<IconData> icons = [
    Icons.dashboard,
    Icons.category,
    Icons.movie,
    Icons.style,
    Icons.production_quantity_limits,
    Icons.visibility,
    Icons.store,
    Icons.book_online,
    Icons.file_copy,
    Icons.feedback,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, // Sidebar width
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 226, 116, 7),
            const Color.fromARGB(255, 43, 43, 43)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              
              // Logo and Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/logo3.png",
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ANIME ARC',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sidebar Menu Items
              ListView.builder(
                shrinkWrap: true,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  bool isSelected = widget.selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        onTap: () {
                          widget.onItemSelected(index);
                        },
                        leading: Icon(
                          icons[index],
                          color: isSelected ? Colors.orangeAccent : Colors.white,
                        ),
                        title: Text(
                          pages[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.orangeAccent : Colors.white,
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
            ],
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: Colors.redAccent.withOpacity(0.2),
              leading: const Icon(Icons.logout_outlined, color: Colors.white),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminLoginApp()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
