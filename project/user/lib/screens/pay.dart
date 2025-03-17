import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/paymentscreen.dart';

class Pay extends StatefulWidget {
  final int bid;
  const Pay({super.key, required this.bid});

  @override
  State<Pay> createState() => _PayState();
}

class _PayState extends State<Pay> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  double totalPayment = 0.0;
  List<Map<String, dynamic>> cartProducts = [];
  
  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchCartDetails();
  }

  Future<void> fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();
      setState(() {
        userData = response;
      });
    }
  }

  Future<void> fetchCartDetails() async {
    final cartResponse = await supabase
        .from('tbl_cart')
        .select('cart_qty, product_id')
        .eq('booking_id', widget.bid);

    double total = 0.0;
    List<Map<String, dynamic>> products = [];

    for (var item in cartResponse) {
      final productResponse = await supabase
          .from('tbl_product')
          .select('product_name, product_image, product_price, product_description')
          .eq('product_id', item['product_id'])
          .single();

      if (productResponse.isNotEmpty) {
        double price = double.tryParse(productResponse['product_price'].toString()) ?? 0.0;
        int quantity = int.tryParse(item['cart_qty'].toString()) ?? 1;
        total += price * quantity;

        products.add({
          'name': productResponse['product_name'],
          'image': productResponse['product_image'],
          'price': price,
          'description': productResponse['product_description'],
          'quantity': quantity,
        });
      }
    }

    setState(() {
      totalPayment = total;
      cartProducts = products;
    });
  }

  void _navigateToPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(bid: widget.bid, total: totalPayment)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Delivery To:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(userData?["user_name"] ?? "", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(userData?["user_address"] ?? "", style: TextStyle(fontSize: 16)),
                  Text("Contact: ${userData?["user_contact"] ?? ""}", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Divider(),
                  const SizedBox(height: 10),
                  Text("Your Order:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartProducts.length,
                      itemBuilder: (context, index) {
                        var product = cartProducts[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Image.network(product['image'], width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(product['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${product['description']}", maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text("Quantity: ${product['quantity']}"),
                              ],
                            ),
                            trailing: Text("\$${product['price'].toStringAsFixed(2)}"),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(),
                  const SizedBox(height: 10),
                  Text("Order Total: \$${totalPayment.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _navigateToPaymentScreen, // Navigate to PaymentScreen
                      child: const Text("Proceed to Payment"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}