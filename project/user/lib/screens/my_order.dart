import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user/main.dart';
import 'package:user/screens/order_details.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user/theme/anime_theme.dart' as animeTheme;
import 'package:user/utils/order_status.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final bookings = await supabase
          .from('tbl_booking')
          .select('''
            *,
            tbl_cart (
              cart_id,
              cart_qty,
              cart_status,
              tbl_product (*)
            )
          ''')
          .eq('user_id', user.id)
          .gte('booking_status', OrderStatus.CONFIRMED)
          .order('booking_data', ascending: false);

      List<Map<String, dynamic>> orderList = [];
      
      for (var booking in bookings) {
        final carts = booking['tbl_cart'] as List;
        for (var cart in carts) {
          final product = cart['tbl_product'];
          if (product != null) {
            orderList.add({
              "id": cart['cart_id'],
              "order_id": booking['booking_id'],
              "product_id": product['product_id'],
              "name": product['product_name'],
              "image": product['product_image'],
              "price": double.tryParse(product['product_price'].toString()) ?? 0.0,
              "quantity": int.tryParse(cart['cart_qty'].toString()) ?? 0,
              "status": int.tryParse(cart['cart_status'].toString()) ?? 0,
              "date": booking['booking_data'],
              "tracking_id": booking['booking_trackid'],
            });
          }
        }
      }

      setState(() {
        orders = orderList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AnimeTheme.primaryPurple,
              AnimeTheme.darkPurple,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedAppBar(),
              _buildOrderTabs(),
              Expanded(
                child: isLoading
                    ? _buildShimmerEffect()
                    : orders.isEmpty
                        ? _buildEmptyOrders()
                        : _buildOrdersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  "My Orders",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  setState(() => isLoading = true);
                  fetchOrders();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [
              animeTheme.AnimeTheme.accentPink,
              AnimeTheme.brightPurple,
            ],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: "All"),
          Tab(text: "Active"),
          Tab(text: "Completed"),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOrdersListView(orders),
        _buildOrdersListView(orders.where((order) => order['status'] != 3).toList()),
        _buildOrdersListView(orders.where((order) => order['status'] == 3).toList()),
      ],
    );
  }

  Widget _buildOrdersListView(List<Map<String, dynamic>> filteredOrders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        var order = filteredOrders[index];
        String orderDate = _formatDate(order['date']);
        
        // Group orders by date
        bool showDateHeader = index == 0 || 
            _formatDate(filteredOrders[index - 1]['date']) != orderDate;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  orderDate,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            _buildEnhancedOrderCard(order),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as int;
    final hasTracking = order['tracking_id'] != null && order['tracking_id'].toString().isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OrderStatus.getColor(status).withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(
                orderId: order['order_id'],
              ),
            ),
          ).then((_) => fetchOrders()), // Refresh after returning
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Order Header
                Row(
                  children: [
                    Icon(
                      OrderStatus.getIcon(status),
                      color: OrderStatus.getColor(status),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Order #${order['order_id']}",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: OrderStatus.getColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        OrderStatus.getText(status),
                        style: GoogleFonts.poppins(
                          color: OrderStatus.getColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                // Product Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Hero(
                      tag: 'order_image_${order["id"]}',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            order['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[850],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order['status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(order['status']),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                currencyFormat.format(
                                  double.parse(order['price'].toString()),
                                ),
                                style: GoogleFonts.poppins(
                                  color: AnimeTheme.accentPink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Qty: ${order['quantity']}",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(order['date']),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int? status) {
    switch (status) {
      case 1:
        return "Confirmed";
      case 2:
        return "Shipped";
      case 3:
        return "Delivered";
      default:
        return "Processing";
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Unknown date";
    DateTime date = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return "";
    DateTime date = DateTime.parse(dateString);
    return DateFormat('h:mm a').format(date);
  }

  // 🔥 Empty Order State
  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE991FF).withOpacity(0.3),
                  const Color(0xFFBF55EC).withOpacity(0.3),
                ],
              ),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 70,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No confirmed orders found",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF55EC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              "Explore Store",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Shimmer Effect while loading orders
  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF2D0A4D),
          highlightColor: const Color(0xFF4A1A70),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 15, width: 120, color: Colors.grey[800]),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 60, color: Colors.grey[800]),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 80, color: Colors.grey[800]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
