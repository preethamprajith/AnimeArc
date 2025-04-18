import 'package:animearc_admin/screens/managemanga.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animearc_admin/components/appbar.dart';
import 'package:animearc_admin/components/sidebar.dart';
import 'package:animearc_admin/screens/manageanime.dart';
import 'package:animearc_admin/screens/managebooking.dart';
import 'package:animearc_admin/screens/managecategory.dart';
import 'package:animearc_admin/screens/managegenre.dart';
import 'package:animearc_admin/screens/manageproduct.dart';
import 'package:animearc_admin/screens/viewproduct.dart';
import 'package:animearc_admin/screens/views&complaints.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

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
  int totalBookings = 0;

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
      final bookingResponse = await supabase.from('tbl_booking').select('booking_id');

      setState(() {
        totalUsers = userResponse.length;
        totalStock = stockResponse.fold<int>(0, (sum, item) => sum + (item['stock_qty'] as int));
        totalProducts = productResponse.length;
        totalBookings = bookingResponse.length;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  final List<Widget> _pages = [
    const DashboardContent(),
    ManageCategory(),
    ManageAnime(),
    ManageGenre(),
    ManageProduct(),
    ViewProduct(),
    Managebooking(),
    ManageManga(),
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/123.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A0933).withOpacity(0.85), // Dark purple
                Color(0xFF2D1155).withOpacity(0.9), // Medium purple
              ],
            ),
          ),
          child: Row(
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
                    const Appbar1(),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: _selectedIndex == 0 
                        ? DashboardSummary(
                            totalUsers: totalUsers,
                            totalStock: totalStock,
                            totalProducts: totalProducts,
                            totalBookings: totalBookings,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: _pages[_selectedIndex],
                          ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardSummary extends StatelessWidget {
  final int totalUsers;
  final int totalStock;
  final int totalProducts;
  final int totalBookings;

  const DashboardSummary({
    required this.totalUsers,
    required this.totalStock,
    required this.totalProducts,
    required this.totalBookings,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            'Welcome to AnimeArc Admin',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        FadeInDown(
          duration: const Duration(milliseconds: 700),
          child: Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[300],
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Stats cards
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // First row of stats
                    Row(
                      children: [
                        Expanded(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            child: DashboardCard(
                              title: "Total Users",
                              value: totalUsers.toString(),
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFF8A2BE2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 700),
                            child: DashboardCard(
                              title: "Total Stock",
                              value: totalStock.toString(),
                              icon: Icons.inventory_rounded,
                              color: const Color(0xFF5D1E9E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Second row of stats
                    Row(
                      children: [
                        Expanded(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            child: DashboardCard(
                              title: "Products",
                              value: totalProducts.toString(),
                              icon: Icons.shopping_bag_rounded,
                              color: const Color(0xFF42E8E0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 900),
                            child: DashboardCard(
                              title: "Bookings",
                              value: totalBookings.toString(),
                              icon: Icons.book_online_rounded,
                              color: const Color(0xFFAA7EE0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Activity chart
                    Expanded(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Activity Overview",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            const style = TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12,
                                            );
                                            String text;
                                            switch (value.toInt()) {
                                              case 0:
                                                text = 'Mon';
                                                break;
                                              case 2:
                                                text = 'Wed';
                                                break;
                                              case 4:
                                                text = 'Fri';
                                                break;
                                              case 6:
                                                text = 'Sun';
                                                break;
                                              default:
                                                return Container();
                                            }
                                            return Text(text, style: style);
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: const [
                                          FlSpot(0, 3),
                                          FlSpot(1, 1),
                                          FlSpot(2, 4),
                                          FlSpot(3, 2),
                                          FlSpot(4, 5),
                                          FlSpot(5, 3),
                                          FlSpot(6, 4),
                                        ],
                                        isCurved: true,
                                        color: const Color(0xFF8A2BE2),
                                        barWidth: 3,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: const Color(0xFF8A2BE2).withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right column
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Recent Updates Card
                    Expanded(
                      child: FadeInRight(
                        duration: const Duration(milliseconds: 800),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Recent Updates",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    _buildUpdateItem(
                                      icon: Icons.add_circle,
                                      title: "New Anime Added",
                                      subtitle: "Demon Slayer Season 3",
                                      time: "2 hours ago",
                                      color: Colors.green,
                                    ),
                                    _buildUpdateItem(
                                      icon: Icons.shopping_cart,
                                      title: "New Order Received",
                                      subtitle: "3 items - ₹2,500",
                                      time: "5 hours ago",
                                      color: Colors.blue,
                                    ),
                                    _buildUpdateItem(
                                      icon: Icons.people,
                                      title: "New User Registered",
                                      subtitle: "John Doe",
                                      time: "1 day ago",
                                      color: Colors.purple,
                                    ),
                                    _buildUpdateItem(
                                      icon: Icons.star,
                                      title: "New Review",
                                      subtitle: "5 stars - One Piece Figure",
                                      time: "2 days ago",
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Popular Anime Card
                    Expanded(
                      child: FadeInRight(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Popular Anime",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    _buildPopularAnimeItem(
                                      title: "Demon Slayer",
                                      views: "4.5K views",
                                      percentage: 0.9,
                                    ),
                                    _buildPopularAnimeItem(
                                      title: "One Piece",
                                      views: "3.2K views",
                                      percentage: 0.8,
                                    ),
                                    _buildPopularAnimeItem(
                                      title: "Jujutsu Kaisen",
                                      views: "2.9K views",
                                      percentage: 0.75,
                                    ),
                                    _buildPopularAnimeItem(
                                      title: "Attack on Titan",
                                      views: "2.4K views",
                                      percentage: 0.65,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularAnimeItem({
    required String title,
    required String views,
    required double percentage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                views,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF8A2BE2),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Loading dashboard data...'));
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
