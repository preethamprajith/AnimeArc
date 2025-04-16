import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
          .select('*, booking_trackid')
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
        double price =
            double.tryParse(item['tbl_product']['product_price'].toString()) ??
                0.0;
        double total = price * quantity;

        return {
          "id": item['cart_id'],
          "product": item['tbl_product']['product_name'] ?? "Unknown Product",
          "image": item['tbl_product']['product_image'] ?? "",
          "price": price,
          "quantity": quantity,
          "total": total,
          "status": item['cart_status'],
          "booking_trackid": orderResponse['booking_trackid'] ?? '',
        };
      }).toList();

      setState(() {
        orderDetails = {
          ...orderResponse,
          "booking_status":
              int.tryParse(orderResponse['booking_status'].toString()) ?? 0,
          "total_amount":
              double.tryParse(orderResponse['booking_amount'].toString()) ?? 0.0,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Order #${widget.orderId}",
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16)))
              : orderDetails == null
                  ? const Center(
                      child: Text("Order not found",
                          style: TextStyle(color: Colors.white)))
                  : buildOrderDetails(),
    );
  }

  Widget buildOrderDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Order Items",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      return buildOrderItemCard(item);
                    },
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey),
                  Text(
                      "Total Amount: ₹${orderDetails!["total_amount"].toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrderItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item['image'].isNotEmpty
                  ? Image.network(item['image'],
                      width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['product'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(
                      "Qty: ${item['quantity']} - ₹${item['price'].toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white70)),
                  Text("Total: ₹${item['total'].toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 5),
                  Chip(
                    backgroundColor:
                        getOrderStatusColor(item['status']).withOpacity(0.2),
                    label: Text(getOrderStatusText(item['status']),
                        style: TextStyle(
                            color: getOrderStatusColor(item['status']),
                            fontWeight: FontWeight.bold)),
                  ),
                  if (item['status'] == 3 && item['booking_trackid'].isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final trackId = item['booking_trackid'].toString();
                        final url =
                            'https://www.indiapost.gov.in/_layouts/15/dop.portal.tracking/trackconsignment.aspx?tracknum=$trackId';
                        await Clipboard.setData(ClipboardData(text: trackId));
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Could not launch tracking URL")),
                          );
                        }
                      },
                      icon: const Icon(Icons.local_shipping_outlined,
                          color: Colors.white70),
                      label: Text("Track ID: ${item['booking_trackid']}",
                          style: const TextStyle(color: Colors.white70)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getOrderStatusText(int status) {
    switch (status) {
      case 1:
        return "Confirmed";
      case 2:
        return "Shipped";
      case 3:
        return "Delivered";
      default:
        return "Cancelled";
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
      default:
        return Colors.red;
    }
  }
}