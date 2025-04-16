import 'package:animearc_admin/screens/manageanimefile.dart';
import 'package:animearc_admin/screens/managemanga.dart';
import 'package:animearc_admin/screens/managemangafile.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animearc_admin/components/appbar.dart';
import 'package:animearc_admin/components/sidebar.dart';
import 'package:animearc_admin/screens/manageanime.dart';
import 'package:animearc_admin/screens/managebooking.dart';
import 'package:animearc_admin/screens/managecategory.dart';
import 'package:animearc_admin/screens/managegenre.dart';
import 'package:animearc_admin/screens/manageproduct.dart';
import 'package:animearc_admin/screens/managestock.dart';
import 'package:animearc_admin/screens/viewproduct.dart';
import 'package:animearc_admin/screens/views&complaints.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  int totalUsers = 0;
  int totalStock = 0;
  int totalProducts = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final supabase = Supabase.instance.client;

    try {
      final userResponse = await supabase.from('tbl_user').select('user_id');
      final stockResponse = await supabase.from('tbl_stock').select('stock_qty');
      final productResponse = await supabase.from('tbl_product').select('product_id');

      setState(() {
        totalUsers = userResponse.length;
        totalStock = stockResponse.fold<int>(0, (sum, item) => sum + (item['stock_qty'] as int));
        totalProducts = productResponse.length;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  final List<Widget> _pages = [
    const Center(child: Text('Dashboard Content')),
    ManageCategory(),
    ManageAnime(),
    ManageGenre(),
    ManageProduct(),
    ViewProduct(),
    Managestock(),
    Managebooking(),
    UploadAnimeVideo(),
    ManageManga(),
    Managemangafile(),
    ComplaintPage(),
    
  ];

  void onSidebarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: SideBar(
              onItemSelected: onSidebarItemTapped,
              selectedIndex: _selectedIndex,
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Appbar1(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color.fromARGB(255, 222, 149, 54), const Color.fromARGB(255, 196, 128, 32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Admin!',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FadeInUp(
                              duration: Duration(milliseconds: 500),
                              child: DashboardCard(title: "Total Users", value: totalUsers.toString(), icon: Icons.person_outline),
                            ),
                            FadeInUp(
                              duration: Duration(milliseconds: 600),
                              child: DashboardCard(title: "Total Stock", value: totalStock.toString(), icon: Icons.inventory_2_outlined),
                            ),
                            FadeInUp(
                              duration: Duration(milliseconds: 700),
                              child: DashboardCard(title: "Total Products", value: totalProducts.toString(), icon: Icons.shopping_bag),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2, offset: Offset(0, 4)),
                              ],
                            ),
                            padding: EdgeInsets.all(16),
                            child: _pages[_selectedIndex],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({required this.title, required this.value, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.9),
      shadowColor: Colors.black38,
      child: Container(
        width: 180,
        padding: EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: Colors.blueAccent),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }
}
