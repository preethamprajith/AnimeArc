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
  TextEditingController addressController = TextEditingController();
  TextEditingController contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTotalPayment();
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
        addressController.text = userData?['user_address'] ?? '';
        contactController.text = userData?['user_contact'] ?? '';
      });
    }
  }

  Future<void> fetchTotalPayment() async {
    final response = await supabase
        .from('tbl_cart')
        .select('cart_qty, product_id')
        .eq('booking_id', widget.bid);

    double total = 0.0;

    for (var item in response) {
      final productResponse = await supabase
          .from('tbl_product')
          .select('product_price')
          .eq('product_id', item['product_id'])
          .single();

      if (productResponse.isNotEmpty) {
        double price = double.tryParse(productResponse['product_price'].toString()) ?? 0.0;
        int quantity = int.tryParse(item['cart_qty'].toString()) ?? 1;
        total += price * quantity;
      }
    }

    setState(() {
      totalPayment = total;
    });
  }

  void _editContactAndAddress() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Contact & Address"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: contactController, decoration: const InputDecoration(labelText: "Contact")),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: "New Address")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final user = supabase.auth.currentUser;
                if (user != null) {
                  await supabase.from('tbl_user').update({
                    'user_address': addressController.text,
                    'user_contact': contactController.text,
                  }).eq('user_id', user.id);
                  setState(() {
                    userData?['user_address'] = addressController.text;
                    userData?['user_contact'] = contactController.text;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

 void _navigateToPaymentScreen() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => PaymentScreen(bid: widget.bid)),
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
                  ElevatedButton(
                    onPressed: _editContactAndAddress,
                    child: const Text("Edit Contact & Address"),
                  ),
                  const SizedBox(height: 20),
                  Divider(),
                  const SizedBox(height: 10),
                  Text("Order Total: ₹${totalPayment.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
