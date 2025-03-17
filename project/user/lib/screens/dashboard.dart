import 'package:flutter/material.dart';
import 'package:user/screens/account.dart';
import 'package:user/screens/browse.dart';
import 'package:user/screens/mylist.dart';
import 'package:user/screens/store.dart';
import 'package:user/screens/userhome.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex =0;
  final List<Widget> items =[
    Userhome(),
    MyList(),
    Store(),
    Browse(),
    Account(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
  body: items[_selectedIndex],
  bottomNavigationBar: BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.black, // Set navigation bar color to black
    selectedItemColor: Colors.grey, // Selected icon color set to grey
    unselectedItemColor: Colors.grey, // Unselected icon color set to grey
    currentIndex: _selectedIndex,
    onTap: (index) {
      setState(() {
        _selectedIndex = index;
      });
    },
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: 'MYLIST',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.store),
        label: 'STORE',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.open_in_browser),
        label: 'BROWSE',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.manage_accounts_outlined),
        label: 'ACCOUNT',
      ),
    ],
  ),
);
  }
}