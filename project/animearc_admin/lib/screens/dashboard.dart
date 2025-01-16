import 'package:animearc_admin/components/appbar.dart';
import 'package:animearc_admin/components/sidebar.dart';
import 'package:animearc_admin/screens/manageanime.dart';
import 'package:animearc_admin/screens/managebooking.dart';
import 'package:animearc_admin/screens/managecategory.dart';
import 'package:animearc_admin/screens/managegenre.dart';
import 'package:animearc_admin/screens/manageproduct.dart';
import 'package:animearc_admin/screens/managestock.dart';
import 'package:animearc_admin/screens/views&complaints.dart';
import 'package:flutter/material.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Dashboard Content')),
    Managecategory(),
    Manageanime(),
    Managegenre(),
    Manageproduct(),
    Managestock(),
    Managebooking(),
    Viewscomplaints(),
    const Center(child: Text('Settings Content')),
  ];

  void onSidebarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Row(
          children: [
            Expanded(
                flex: 1,
                child: SideBar(
                  onItemSelected: onSidebarItemTapped,
                )),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Appbar1(),
                  _pages[_selectedIndex],
                ],
              ),
            )
          ],
        ));
  }
}
