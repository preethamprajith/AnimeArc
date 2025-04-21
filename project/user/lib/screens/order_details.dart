import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
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

      final List<Map<String, dynamic>> items = itemsResponse.map((item) {
        final product = item['tbl_product'] ?? {};
        int quantity = int.tryParse(item['cart_qty'].toString()) ?? 1;
        double price = double.tryParse(product['product_price'].toString()) ?? 0.0;
        return {
          "id": item['cart_id'],
          "product": product['product_name'] ?? "Unknown",
          "image": product['product_image'] ?? "",
          "price": price,
          "quantity": quantity,
          "total": price * quantity,
          "status": item['cart_status'],
          "booking_trackid": orderResponse['booking_trackid'] ?? '',
          "tbl_product": product, // Add this line to include the full product data
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Order #${widget.orderId}", style: const TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4A1A70),
        centerTitle: true,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) => buildOrderItemCard(orderItems[index]),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey),
                  Text(
                    "Total Amount: ₹${orderDetails!["total_amount"].toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrderItemCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 0;
    final trackId = item['booking_trackid'] ?? '';
    final canTrack = (status == 2 || status == 3) && trackId.toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item['image'].toString().isNotEmpty
                  ? Image.network(item['image'], width: 60, height: 60, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['product'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Qty: ${item['quantity']} - ₹${item['price'].toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white70)),
                  Text("Total: ₹${item['total'].toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 6),
                  Chip(
                    backgroundColor: getOrderStatusColor(status).withOpacity(0.2),
                    label: Text("${getOrderStatusText(status)} ($status)",
                        style: TextStyle(color: getOrderStatusColor(status))),
                  ),
                  if (canTrack) ...[
                    const SizedBox(height: 4),
                    Text("Track ID: $trackId", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final url =
                              'https://www.indiapost.gov.in/_layouts/15/dop.portal.tracking/trackconsignment.aspx?tracknum=$trackId';
                          await Clipboard.setData(ClipboardData(text: trackId));
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not launch tracking URL")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error in tracking: $e"), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.local_shipping_outlined, color: Colors.white70),
                      label: Text("Track Shipment", style: const TextStyle(color: Colors.white70)),
                    ),
                  ],
                  if (status == 3) ...[  // Only show review button for delivered items
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(item),
                      icon: const Icon(Icons.rate_review, color: Colors.white),
                      label: const Text('Write Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
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

  Future<void> _showReviewDialog(Map<String, dynamic> item) async {
    // Check if we have the product data
    final productData = item['tbl_product'];
    if (productData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product information not found')),
      );
      return;
    }

    final productId = productData['product_id'];
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID not found')),
      );
      return;
    }

    final _reviewController = TextEditingController();
    double _rating = 3.0;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Review ${item['product'] ?? 'Product'}',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ...existing RatingBar code...
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                _rating = rating;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your review...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_reviewController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please write a review')),
                );
                return;
              }
              Navigator.pop(context);
              _submitReview(productId, _rating, _reviewController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );

    // Dispose the controller
    _reviewController.dispose();
  }

  Future<void> _submitReview(int productId, double rating, String content) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to submit a review')),
          );
        }
        return;
      }

      await supabase.from('tbl_review').insert({
        'review_rating': rating.toString(),
        'review_content': content.trim(),
        'review_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'product_id': productId,
        'anime_id': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    }
  }
}
