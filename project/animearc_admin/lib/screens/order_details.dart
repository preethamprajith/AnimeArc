import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsPage extends StatefulWidget {
  final int bid;
  const OrderDetailsPage({super.key, required this.bid});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  List<Map<String, dynamic>> orderItems = [];
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> fetchItems() async {
    try {
      print("Fetching items for booking_id: ${widget.bid}");
      final response = await supabase
          .from('tbl_cart')
          .select("*, tbl_product(*)")
          .eq('booking_id', widget.bid);

      print("Supabase Response: $response");

      if (response.isEmpty) {
        print("No items found for booking_id: ${widget.bid}");
        setState(() => orderItems = []);
        return;
      }

      List<Map<String, dynamic>> items = response.map((item) {
        int quantity = int.tryParse(item['cart_qty'].toString()) ?? 0;
        double price = double.tryParse(item['tbl_product']['product_price'].toString()) ?? 0.0;
        double total = price * quantity;

        return {
          'id': item['cart_id'],
          'product': item['tbl_product']['product_name'] ?? "Unknown Product",
          'image': item['tbl_product']['product_image'] ?? "",
          'qty': quantity,
          'price': price,
          'total': total,
          'status': item['cart_status']
        };
      }).toList();

      setState(() => orderItems = items);
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  Future<void> update(int id, int status) async {
    try {
      await supabase.from('tbl_cart').update({'cart_status': status + 1}).eq('cart_id', id);
      fetchItems();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order status updated!")));
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Details",
              style: GoogleFonts.sanchez(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3)),
                  ],
                ),
                child: orderItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text("No items in this order", style: GoogleFonts.sanchez(fontSize: 16, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: orderItems.length,
                        itemBuilder: (context, index) {
                          final item = orderItems[index];
                          return _buildOrderItemCard(item);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(Map<String, dynamic> item) {
    Color statusColor;
    String status = "";
    String btn = "";
    switch (item['status']) {
      case 1:
        statusColor = Colors.blue;
        status = "Confirmed";
        btn = "Order Packed";
        break;
      case 2:
        statusColor = Colors.orange;
        status = "Order Packed";
        btn = "Order Completed";
        break;
      case 3:
        statusColor = Colors.green;
        status = "Order Complete";
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['product'], style: GoogleFonts.sanchez(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text("Qty: ${item['qty']}  |  Price: ₹${item['price'].toStringAsFixed(2)}", style: GoogleFonts.sanchez(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text("Total: ₹${item['total'].toStringAsFixed(2)}", style: GoogleFonts.sanchez(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  if (item['status'] < 3)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => update(item['id'], item['status']),
                        style: TextButton.styleFrom(backgroundColor: statusColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        child: Text(btn, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}