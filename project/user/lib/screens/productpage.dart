import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductPage extends StatefulWidget {
  final int productId; // Pass only item ID

  const ProductPage({super.key, required this.productId});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? product;
  bool isLoading = true;
  int quantity = 1;
  double averageRating = 0.0;
  int reviewCount = 0;
  List<Map<String, dynamic>> reviews = [];
  bool isInStock = false;
  int maxStock = 0;

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
    fetchReviews();
  }

  Future<void> fetchProductDetails() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select('''
            *,
            tbl_stock (
              stock_id,
              stock_qty
            )
          ''')
          .eq('product_id', widget.productId)
          .single();

      if (mounted) {
        setState(() {
          product = response;
          
          // Calculate total stock
          final stockDataList = product?['tbl_stock'] as List?;
          int totalStockQty = 0;

          if (stockDataList != null && stockDataList.isNotEmpty) {
            for (var stockData in stockDataList) {
              final qty = int.tryParse(stockData['stock_qty'].toString()) ?? 0;
              totalStockQty += qty;
            }
          }

          maxStock = totalStockQty; // Set maximum stock
          isInStock = totalStockQty > 0;
          product?['total_stock'] = totalStockQty;
          isLoading = false;

          // Debug print
          print('Product: ${product?['product_name']}, Total Stock: $totalStockQty');
        });
      }
    } catch (e) {
      print('Error fetching product details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchReviews() async {
    try {
      final response = await supabase
          .from('tbl_review')
          .select('''
            review_rating,
            review_content,
            review_date,
            tbl_user (
              user_name
            )
          ''')
          .eq('product_id', widget.productId);

      if (mounted) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(response);
          if (reviews.isNotEmpty) {
            double total = 0;
            for (var review in reviews) {
              total += double.parse(review['review_rating'].toString());
            }
            averageRating = total / reviews.length;
            reviewCount = reviews.length;
          }
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  void updateQuantity(bool increment) {
    setState(() {
      if (increment) {
        if (quantity < maxStock) {
          quantity++;
        } else {
          // Show message when trying to exceed stock
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum available stock is $maxStock'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else if (!increment && quantity > 1) {
        quantity--;
      }
    });
  }

  Future<void> addToCart(int id) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to add items to cart")),
        );
        return;
      }

      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('booking_status', 0)
          .eq('user_id', user.id)
          .maybeSingle()
          .limit(1);

      int bookingId;
      if (booking == null) {
        final response = await supabase
            .from('tbl_booking')
            .insert([
              {
                'user_id': user.id,
                'booking_status': 0,
                'booking_data': DateTime.now().toIso8601String(),
              }
            ])
            .select("booking_id")
            .single();
        bookingId = response['booking_id'];
      } else {
        bookingId = booking['booking_id'];
      }

      final cartResponse = await supabase
          .from('tbl_cart')
          .select()
          .eq('booking_id', bookingId)
          .eq('product_id', id);

      if (cartResponse.isEmpty) {
        await addCart(context, bookingId, id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product already in cart")),
        );
      }
    } catch (e) {
      print('Error add to cart: $e');
    }
  }

  Future<void> addCart(BuildContext context, int bid, int cid) async {
    try {
      await supabase.from('tbl_cart').insert([
        {
          'booking_id': bid,
          'product_id': cid,
          'cart_qty': quantity.toString(),
          'cart_status': 0,
        }
      ]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to cart"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : product == null
              ? const Center(
                  child: Text(
                    "Product not found",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 400,
                      pinned: true,
                      backgroundColor: Colors.black,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'product_${product?['product_id']}',
                              child: Image.network(
                                product?['product_image'] ??
                                    'https://via.placeholder.com/400',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[900],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 100,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -30),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 25),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product?['product_name'] ??
                                                'Unknown Item',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              RatingBarIndicator(
                                                rating: averageRating,
                                                itemBuilder: (context, index) =>
                                                    const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                itemCount: 5,
                                                itemSize: 20.0,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '($reviewCount reviews)',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "₹${product?['product_price'] ?? 'N/A'}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Description",
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product?['product_description'] ??
                                            'No details available',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (reviews.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Reviews",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...reviews.map((review) => Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[850],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                RatingBarIndicator(
                                                  rating: double.parse(review[
                                                          'review_rating']
                                                      .toString()),
                                                  itemBuilder:
                                                      (context, index) =>
                                                          const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                  ),
                                                  itemCount: 5,
                                                  itemSize: 16.0,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  review['tbl_user']
                                                          ['user_name'] ??
                                                      'Anonymous',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              review['review_content'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ))
                                      .toList(),
                                ],
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[850],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove,
                                                color: Colors.white),
                                            onPressed: () =>
                                                updateQuantity(false),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              quantity.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add,
                                                color: Colors.white),
                                            onPressed: () =>
                                                updateQuantity(true),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: isInStock ? () {
                                          addToCart(product?['product_id']);
                                        } : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isInStock ? const Color(0xFF4A1A70) : Colors.grey,
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.shopping_cart),
                                            const SizedBox(width: 8),
                                            Text(
                                              isInStock ? 'Add to Cart' : 'Out of Stock',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isInStock ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        isInStock ? 'IN STOCK' : 'OUT OF STOCK',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isInStock) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Available: ${product?['total_stock'] ?? 0}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
