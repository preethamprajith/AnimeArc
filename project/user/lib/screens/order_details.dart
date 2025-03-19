import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user/main.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? orderDetails;
  List<Map<String, dynamic>> orderItems = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      final orderResponse = await supabase
          .from('tbl_booking')
          .select()
          .eq('booking_id', widget.orderId)
          .maybeSingle();

      if (orderResponse == null) {
        setState(() {
          errorMessage = "Order not found!";
          isLoading = false;
        });
        return;
      }

      final itemsResponse = await supabase
          .from('tbl_cart')
          .select('*, tbl_product(*)')
          .eq('booking_id', widget.orderId);

      List<Map<String, dynamic>> items = itemsResponse.map((item) {
        int quantity = int.tryParse(item['cart_qty'].toString()) ?? 1;
        double price = double.tryParse(item['tbl_product']['product_price'].toString()) ?? 0.0;
        double total = price * quantity;

        return {
          "id": item['cart_id'],
          "product": item['tbl_product']['product_name'] ?? "Unknown Product",
          "image": item['tbl_product']['product_image'] ?? "",
          "price": price,
          "quantity": quantity,
          "total": total,
          "status": item['cart_status']
        };
      }).toList();

      setState(() {
        orderDetails = {
          ...orderResponse,
          "booking_status": int.tryParse(orderResponse['booking_status'].toString()) ?? 0,
          "total_amount": double.tryParse(orderResponse['booking_amount'].toString()) ?? 0.0,
        };
        orderItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching order details: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order #${widget.orderId}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
              : orderDetails == null
                  ? const Center(child: Text("Order not found"))
                  : buildOrderDetails(),
    );
  }

  Widget buildOrderDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Order Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orderItems.length,
            itemBuilder: (context, index) {
              final item = orderItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: item['image'].isNotEmpty
                      ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  title: Text(item['product'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Qty: ${item['quantity']} - ₹${item['price'].toStringAsFixed(2)}"),
                      Text("Total: ₹${item['total'].toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: getOrderStatusColor(item['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          getOrderStatusText(item['status']),
                          style: TextStyle(color: getOrderStatusColor(item['status']), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

        ],
      ),
    );
  }

  String getOrderStatusText(int status) {
    switch (status) {
      case 1:
        return 'Processing';
      case 2:
        return 'Shipped';
      case 3:
        return 'Delivered';
      case 4:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color getOrderStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}