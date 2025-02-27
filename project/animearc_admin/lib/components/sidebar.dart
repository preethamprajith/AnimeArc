import 'package:animearc_admin/screens/login.dart';
import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  final Function(int) onItemSelected;
  const SideBar({super.key, required this.onItemSelected});

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
    "VIEWS AND REVIEW COMPLAINT",
    "SETTINGS"
  ];
  final List<IconData> icons = [
    Icons.house,
    Icons.category,
    Icons.animation_outlined,
    Icons.generating_tokens,
    Icons.production_quantity_limits,
    Icons.shopping_cart_checkout,
    Icons.production_quantity_limits,
    Icons.book_online,
    Icons.view_agenda,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        const Color.fromARGB(255, 226, 116, 7),
        const Color.fromARGB(255, 43, 43, 43)
      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
/*             crossAxisAlignment: CrossAxisAlignment.stretch,
 */
            children: [
              SizedBox(
                height: 20,
              ),
              Container(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/logo3.png",
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ANIME ARC',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            Color.fromARGB(255, 0, 0, 0), // Orange text color
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        widget.onItemSelected(index);
                      },
                      leading: Icon(icons[index], color: Colors.white),
                      title: Text(pages[index],
                          style: TextStyle(color: Colors.white)),
                    );
                  }),
            ],
          ),
          ListTile(
            leading: Icon(Icons.logout_outlined, color: Colors.white),
            title: Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => AdminLoginApp()));
            },
          ),
        ],
      ),
    );
  }
}
