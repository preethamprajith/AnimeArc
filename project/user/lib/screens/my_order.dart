import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:user/screens/order_details.dart';


class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final bookings = await supabase
          .from('tbl_booking')
          .select('booking_id')
          .eq('user_id', user.id)
          .eq('booking_status', 2); // Fetch confirmed orders

      if (bookings.isEmpty) {
        setState(() {
          orders = [];
          isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> orderList = [];
      for (var booking in bookings) {
        final cartResponse = await supabase
            .from('tbl_cart')
            .select('*')
            .eq('booking_id', booking['booking_id']);

        for (var cartItem in cartResponse) {
          final productResponse = await supabase
              .from('tbl_product')
              .select('product_name, product_image, product_price')
              .eq('product_id', cartItem['product_id'])
              .maybeSingle();

          if (productResponse != null) {
            orderList.add({
              "id": cartItem['id'],
              "order_id": cartItem['booking_id'],
              "product_id": cartItem['product_id'],
              "name": productResponse['product_name'],
              "image": productResponse['product_image'],
              "price": productResponse['product_price'],
              "quantity": cartItem['cart_qty'],
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
      appBar: AppBar(
        title: Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text("No confirmed orders found"))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsPage(
                              orderId: order['order_id'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  order['image'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image_not_supported),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text("₹${order['price']}",
                                        style: TextStyle(color: Colors.blue)),
                                    Text("Quantity: ${order['quantity']}",
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
