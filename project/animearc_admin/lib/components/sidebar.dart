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
    "MANAGE CATEGORY",
    "MANAGE ANIME",
    "MANAGE GENRE",
    "MANAGE PRODUCT",
    "MANAGE STOCK",
    "MANAGE BOOKING",
    "VIEWS AND REVIEW COMPLAINT",
    
  ];
  final List<IconData> icons = [
    Icons.category, 
    Icons.animation_outlined, 
    Icons.generating_tokens, 
    Icons.production_quantity_limits,
    Icons.shopping_cart_checkout, 
    Icons.book_online, 
    Icons.view_agenda,
    
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminLoginApp())
              );
            },
          ),
        ],
      ),
    );
  }
}