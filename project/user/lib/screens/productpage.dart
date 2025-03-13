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

 Future<void> addToCart(int id) async {
  try {
    // Check if user is logged in
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please log in to add items to cart")),
      );
      return; // Exit function if user is not logged in
    }

    final booking = await supabase
        .from('tbl_booking')
        .select()
        .eq('booking_status', 0)
        .eq('user_id', user.id)
        .maybeSingle();

    int bookingId;
    if (booking == null) {
      final response = await supabase
          .from('tbl_booking')
          .insert([
            {
              'user_id': user.id,
              'booking_status': 0,
              'booking_data': DateTime.now().toIso8601String(), // 🔹 Ensure booking_data is included
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
        SnackBar(content: Text("Product already in cart")),
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
        'cart_qty': '1',
        'cart_status': 0, // Ensure it's explicitly set to 0
      }
    ]);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added to cart")));
  } catch (e) {
    print('Error adding to cart: $e');
  }
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product?['product_name'] ?? "Loading...")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : product == null
              ? Center(child: Text("Product not found"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        product?['product_image'] ??
                            'https://via.placeholder.com/250',
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image, size: 250),
                      ),
                      SizedBox(height: 16),
                      Text(product?['product_name'] ?? 'Unknown Item',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(product?['product_description'] ?? 'No details available',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),
                      Text(
                          "Price: \$${product?['product_price'] ?? 'N/A'} per dollar",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          addToCart(product?['product_id']);
                        },
                        child: Text("Add to Cart"),
                      ),
                    ],
                  ),
                ),
    );
  }
}