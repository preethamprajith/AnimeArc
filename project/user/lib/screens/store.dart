import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/productpage.dart';

class Store extends StatefulWidget {
  const Store({super.key});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> merchandise = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase.from('tbl_product').select();
      setState(() {
        merchandise = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

      // Debug: Print fetched products
      print("Fetched Products: $merchandise");
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Anime Store", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts, // Allow pull-to-refresh
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: merchandise.length,
                  itemBuilder: (context, index) {
                    return _buildMerchCard(merchandise[index]);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildMerchCard(Map<String, dynamic> item) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item["product_image"] ?? "https://via.placeholder.com/150",
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image,
                  size: 60, color: Colors.white);
            },
          ),
        ),
        title: Text(
          item["product_name"] ?? "Unknown Product",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "\$${item["product_price"] ?? '0.00'}",
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Future Buy Now Functionality

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductPage(productId: item['product_id']),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Buy Now", style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
