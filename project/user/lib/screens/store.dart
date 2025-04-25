import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/cart.dart';
import 'package:user/screens/productpage.dart';
import 'dart:async';

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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select('''
            *,
            tbl_stock (
              stock_qty
            )
          ''')
          .order('product_id');

      List<Map<String, dynamic>> productsWithStock = [];

      // Process each product and its stock
      for (var product in response) {
        final stockDataList = product['tbl_stock'] as List?;
        int totalStockQty = 0;

        // Sum up all stock quantities for this product
        if (stockDataList != null && stockDataList.isNotEmpty) {
          for (var stockData in stockDataList) {
            // Parse stock quantity and handle negative values
            final qty = int.tryParse(stockData['stock_qty'].toString()) ?? 0;
            if (qty > 0) { // Only add positive stock quantities
              totalStockQty += qty;
            }
          }
        }

        // Create a new map with total stock quantity
        final productWithStock = Map<String, dynamic>.from(product);
        productWithStock['stock_quantity'] = totalStockQty;
        productsWithStock.add(productWithStock);

        // Debug print to check stock calculations
        print('Product: ${product['product_name']}, Total Stock: $totalStockQty');
      }

      if (mounted) {
        setState(() {
          merchandise = productsWithStock;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> refreshProducts() async {
    setState(() {
      isLoading = true;
    });
    await fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchProducts,
                  color: Color(0xFF4A1A70),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4A1A70),
                            ),
                          )
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.6,
                            ),
                            itemCount: merchandise.length,
                            itemBuilder: (context, index) {
                              return _buildMerchCard(merchandise[index]);
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refreshProducts,
        backgroundColor: const Color(0xFF4A1A70),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Anime Store",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A1A70), Color(0xFF4A1A70)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4A1A70),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Cart()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchCard(Map<String, dynamic> item) {
    final stockQty = item['stock_quantity'] ?? 0;
    final inStock = stockQty > 0;

    return GestureDetector(
      onTap: () {
        if (!inStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This product is currently out of stock (Available: $stockQty)',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return;
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(productId: item['product_id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2A2A2A),
                  Color(0xFF1A1A1A),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'product-${item['product_id']}',
                      child: Image.network(
                        item["product_image"] ?? "https://via.placeholder.com/150",
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 160,
                            color: Colors.black38,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.white54),
                            ),
                          );
                        },
                      ),
                    ),
                    // Stock Status Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: inStock ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          inStock ? 'IN STOCK' : 'OUT OF STOCK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Price Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          // Safe conversion of price to double before formatting
                          "\$${(double.tryParse(item["product_price"].toString()) ?? 0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,  // Changed from Color(0xFF4A1A70) for better visibility
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    item["product_name"] ?? "Unknown Product",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        inStock ? const Color(0xFF4A1A70) : Colors.grey,
                        inStock ? const Color(0xFF4A1A70) : Colors.grey,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: inStock ? const Color(0xFF4A1A70) : Colors.grey,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: inStock ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductPage(productId: item['product_id']),
                          ),
                        );
                      } : null,
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.white24,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "VIEW MORE",
                              style: TextStyle(
                                color: inStock ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: inStock ? Colors.white : Colors.white54,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}