import 'package:animearc_admin/screens/order_details.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting

class Managebooking extends StatefulWidget {
  const Managebooking({super.key});

  @override
  _ManagebookingState createState() => _ManagebookingState();
}

class _ManagebookingState extends State<Managebooking> {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final response = await supabase
        .from('tbl_booking')
        .select(
            'booking_id, booking_data, booking_status, tbl_cart(cart_qty, product_id, cart_status), tbl_user(user_address)')
        .eq('booking_status', 1)
        .order('booking_id', ascending: false);

    List<Map<String, dynamic>> filteredBookings = [];

    for (var booking in response) {
      if (booking['tbl_cart'] != null) {
        List<dynamic> filteredCart = (booking['tbl_cart'] as List<dynamic>)
            .where((cart) => cart['cart_status'] >= 1)
            .toList();

        if (filteredCart.isNotEmpty) {
          booking['tbl_cart'] = filteredCart;
          booking['total_amount'] = await calculateTotal(filteredCart);
          filteredBookings.add(booking);
        }
      }
    }

    return filteredBookings;
  }

  Future<double> calculateTotal(List<dynamic> cartItems) async {
    double total = 0.0;

    for (var item in cartItems) {
      final productResponse = await supabase
          .from('tbl_product')
          .select('product_price')
          .eq('product_id', item['product_id'])
          .single();

      if (productResponse.isNotEmpty) {
        double price =
            double.tryParse(productResponse['product_price'].toString()) ?? 0.0;
        int quantity = int.tryParse(item['cart_qty'].toString()) ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 214, 139, 28),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("No bookings found.",
                    style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          List<Map<String, dynamic>> bookings = snapshot.data!;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index];
              int? bookingId = booking['booking_id'];
              DateTime? bookingDate = DateTime.tryParse(booking['booking_data']);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text("Booking ID: ${bookingId ?? 'N/A'}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 18)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Date: ${bookingDate != null ? DateFormat('yyyy-MM-dd HH:mm').format(bookingDate) : 'Unknown'}",
                            style: const TextStyle(color: Colors.grey)),
                        Text(
                            "Status: ${booking['booking_status'] ?? 'Unknown'}",
                            style: const TextStyle(color: Colors.grey)),
                        Text(
                            "Total Amount: \$${booking['total_amount']?.toStringAsFixed(2) ?? '0.00'}",
                            style: const TextStyle(
                                color: Colors.green, fontWeight: FontWeight.w500)),
                        Text(
                            "User Address: ${booking['tbl_user']?['user_address'] ?? 'N/A'}",
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              (booking['tbl_cart'] as List<dynamic>?)?.map((cart) {
                                    return Text(
                                        "Product ID: ${cart['product_id']}, Qty: ${cart['cart_qty']}",
                                        style: const TextStyle(fontSize: 14));
                                  }).toList() ??
                                  [],
                        ),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: bookingId != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailsPage(bid: bookingId),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("View Details"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}