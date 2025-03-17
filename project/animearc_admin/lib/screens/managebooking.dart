import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        .select('*, tbl_cart(cart_qty, product_id, cart_status), tbl_user(user_address)')
        .eq('booking_status', 2) // Filter bookings with status 2
        .order('booking_id', ascending: false);

    List<Map<String, dynamic>> filteredBookings = [];

    for (var booking in response) {
      if (booking['tbl_cart'] != null) {
        List<dynamic> filteredCart = (booking['tbl_cart'] as List<dynamic>)
            .where((cart) => cart['cart_status'] == 2)
            .toList();

        if (filteredCart.isNotEmpty) {
          booking['tbl_cart'] = filteredCart;
          booking['total_amount'] = await calculateTotal(filteredCart); // Calculate total price
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
        double price = double.tryParse(productResponse['product_price'].toString()) ?? 0.0;
        int quantity = int.tryParse(item['cart_qty'].toString()) ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No bookings found."));
        }

        List<Map<String, dynamic>> bookings = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            var booking = bookings[index];

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text("Booking ID: ${booking['booking_id']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date: ${booking['booking_data']}"),
                    Text("Status: ${booking['booking_status']}"),
                    Text("Total Amount: \$${booking['total_amount'].toStringAsFixed(2)}"),
                    Text("User Address: ${booking['tbl_user'] != null ? booking['tbl_user']['user_address'] : 'N/A'}"),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (booking['tbl_cart'] as List<dynamic>).map((cart) {
                        return Text("Product ID: ${cart['product_id']}, Qty: ${cart['cart_qty']}");
                      }).toList(),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        );
      },
    );
  }
}
