import 'package:flutter/material.dart';
import 'package:user/main.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:user/utils/order_status.dart';

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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A1A70),
        elevation: 0,
        title: Text(
          "Order #${widget.orderId}",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4A1A70).withOpacity(0.9),
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading order details...",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : buildEnhancedOrderDetails(),
      ),
    );
  }

  Widget buildEnhancedOrderDetails() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Status Timeline
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Status",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                buildOrderTimeline(),
              ],
            ),
          ),

          // Order Items Section
          Text(
            "Order Items",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orderItems.length,
            itemBuilder: (context, index) => buildOrderItemCard(orderItems[index]),
          ),

          // Order Summary
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.2),
                  Colors.purple.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                buildSummaryRow("Subtotal", "₹${orderDetails!["total_amount"].toStringAsFixed(2)}"),
                const Divider(color: Colors.white24),
                buildSummaryRow(
                  "Total",
                  "₹${orderDetails!["total_amount"].toStringAsFixed(2)}",
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: isTotal ? Colors.orange : Colors.white,
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Update the buildOrderTimeline method
  Widget buildOrderTimeline() {
    final status = orderDetails!["booking_status"] as int;
    bool hasDeliveredItems = orderItems.any((item) => item['status'] == 3);
    
    return Column(
      children: [
        buildTimelineTile(
          "Confirmed", 
          1, 
          status >= 1,
        ),
        buildTimelineTile(
          "Shipped", 
          2, 
          status >= 2,
        ),
        buildTimelineTile(
          "Delivered", 
          3, 
          hasDeliveredItems,
        ),
      ],
    );
  }

  // Update the buildTimelineTile method
  Widget buildTimelineTile(String title, int step, bool isCompleted) {
    final Color statusColor = isCompleted 
        ? OrderStatus.getColor(OrderStatus.DELIVERED)
        : step == 3 && !isCompleted
            ? OrderStatus.getColor(OrderStatus.SHIPPED)
            : Colors.grey.withOpacity(0.3);

    final IconData statusIcon = isCompleted 
        ? OrderStatus.getIcon(OrderStatus.DELIVERED)
        : step == 3 && !isCompleted
            ? OrderStatus.getIcon(OrderStatus.SHIPPED)
            : Icons.circle;

    return TimelineTile(
      isFirst: step == OrderStatus.CONFIRMED,
      isLast: step == OrderStatus.DELIVERED,
      beforeLineStyle: LineStyle(
        color: isCompleted 
            ? OrderStatus.getColor(OrderStatus.DELIVERED)
            : Colors.grey.withOpacity(0.3),
      ),
      indicatorStyle: IndicatorStyle(
        width: 30,
        height: 30,
        indicator: Container(
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            statusIcon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: isCompleted ? Colors.white : Colors.grey,
                fontSize: 16,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (step == 3 && !isCompleted) ...[
              const SizedBox(width: 8),
              Text(
                '(In Transit)',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
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
                  if (status == 3) ...[
                    const SizedBox(height: 8),
                    FutureBuilder<bool>(
                      future: _hasUserReviewed(item['tbl_product']['product_id']),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Reviewed',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return ElevatedButton.icon(
                            onPressed: () => _showReviewDialog(item),
                            icon: const Icon(Icons.rate_review, color: Colors.white),
                            label: const Text('Write Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          );
                        }
                      },
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
    final productData = item['tbl_product'];
    if (productData == null || productData['product_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product information not found')),
      );
      return;
    }

    try {
      final hasReviewed = await _hasUserReviewed(productData['product_id']);
      if (hasReviewed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already reviewed this product'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create controller and variables outside dialog
      final reviewController = TextEditingController();
      var rating = 3.0;
      var isSubmitting = false;

      if (!mounted) return;

      try {
        await showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing during submission
          builder: (BuildContext dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async => !isSubmitting,
                child: Dialog(
                  backgroundColor: Colors.grey[900],
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Review ${item['product'] ?? 'Product'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RatingBar.builder(
                            initialRating: rating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 30,
                            itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (newRating) => rating = newRating,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: reviewController,
                            enabled: !isSubmitting,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Write your review...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[850],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: isSubmitting ? null : () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: isSubmitting ? null : () async {
                                  if (reviewController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please write a review')),
                                    );
                                    return;
                                  }

                                  setState(() => isSubmitting = true);

                                  try {
                                    await _submitReview(
                                      productData['product_id'],
                                      rating,
                                      reviewController.text.trim(),
                                    );
                                    if (mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                  } catch (e) {
                                    setState(() => isSubmitting = false);
                                    rethrow;
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Submit Review'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      } finally {
        reviewController.dispose();
      }
    } catch (e) {
      print('Error in review dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error showing review dialog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the page
        setState(() {
          isLoading = true;
        });
        await fetchOrderDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this method to check if product is reviewed
  Future<bool> _hasUserReviewed(int productId) async {
    try {
      final response = await supabase
          .from('tbl_review')
          .select('review_id')
          .eq('product_id', productId)
          .eq('user_id', supabase.auth.currentUser!.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking review status: $e');
      return false;
    }
  }
}
