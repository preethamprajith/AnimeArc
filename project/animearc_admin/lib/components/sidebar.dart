import 'package:flutter/material.dart';

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
    Icons.dashboard,
    Icons.category,
    Icons.movie,
    Icons.style,
    Icons.production_quantity_limits,
    Icons.visibility,
    Icons.store,
    Icons.book_online,
    Icons.file_copy,
    Icons.book,
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
      child: ListView(
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
      
              // Sidebar Menu Items
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  bool isSelected = widget.selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
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
                              isSelected ? Colors.orangeAccent : Colors.white,
                        ),
                        title: Text(
                          pages[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.orangeAccent
                                : Colors.white,
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
        ],
      ),
    );
  }
}
