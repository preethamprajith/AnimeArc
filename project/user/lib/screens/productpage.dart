import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select()
          .eq('product_id', widget.productId)
          .single(); // Fetch single product

      setState(() {
        product = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching product details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateQuantity(bool increment) {
    setState(() {
      if (increment && quantity < 99) {
        quantity++;
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
                                SizedBox(
                                  height: 25,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product?['product_name'] ?? 'Unknown Item',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                            onPressed: () => updateQuantity(true),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          addToCart(product?['product_id']);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shopping_cart),
                                            SizedBox(width: 8),
                                            Text(
                                              "Add to Cart",
                                              style: TextStyle(
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
