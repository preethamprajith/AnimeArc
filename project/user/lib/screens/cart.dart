import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/pay.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  CartState createState() => CartState();
}

class CartState extends State<Cart> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  int? bid;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final booking = await supabase
          .from('tbl_booking')
          .select("booking_id")
          .eq('user_id', userId)
          .eq('booking_status', '0')
          .maybeSingle();

      if (booking == null) {
        setState(() => isLoading = false);
        return;
      }

      int bookingId = booking['booking_id'];
      print(bookingId);
      setState(() => bid = bookingId);

      final cartResponse = await supabase
          .from('tbl_cart')
          .select()
          .eq('booking_id', bookingId)
          .eq('cart_status', '0');
        print(cartResponse);

      List<Map<String, dynamic>> items = [];

      for (var cartItem in cartResponse) {
        final itemResponse = await supabase
            .from('tbl_product')
            .select('product_name, product_image, product_price')
            .eq('product_id', cartItem['product_id'])
            .maybeSingle();

        if (itemResponse != null) {
          items.add({
            "cart_id": cartItem['cart_id'],
            "name": itemResponse['product_name'],
            "image": itemResponse['product_image'],
            "price": double.tryParse(itemResponse['product_price'] ?? '0') ?? 0.0,
            "quantity": int.tryParse(cartItem['cart_qty'] ?? '0') ?? 0,
          });
        }
      }

      setState(() {
        cartItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateCartQuantity(int cartId, int newQty) async {
    try {
      await supabase.from('tbl_cart').update({'cart_qty': newQty.toString()}).eq('cart_id', cartId);
      fetchCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity. Please try again.')),
      );
    }
  }

  Future<void> deleteCartItem(int cartId) async {
    try {
      await supabase.from('tbl_cart').delete().eq('cart_id', cartId);
      fetchCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product. Please try again.')),
      );
    }
  }

  Future<void> confirmOrder() async {
    if (bid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No active booking found.')),
      );
      return;
    }

    try {
      // final response = await supabase
      //     .from('tbl_cart')
      //     .update({'cart_status': 1})
      //     .eq('booking_id', bid!)
      //     .select();

      // await supabase.from('tbl_booking').update({'booking_status': 1}).eq('booking_id', bid!);

    

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('PAYMENT AND ADDRESS DETAILS')),
      // );

      
       await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Pay(bid: bid!)),
    );
    fetchCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  double getTotalPrice() {
    return cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // TextEditingController addressController = TextEditingController();

  // void addAddress(){
  //   showDialog(context: context, builder: (context) {
  //     return AlertDialog(
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           TextFormField(
  //             controller: addressController,
  //             decoration: InputDecoration(hintText: "Enter your address"),
  //           ),
  //           SizedBox(height: 16),
            
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: Text("Cancel"),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             confirmOrder();
  //             Navigator.pop(context);
  //           },
  //           child: Text("Proceed to payment"),
  //         ),
  //       ],
  //     );
  //   },);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Your Cart", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, 
                        size: 80, 
                        color: Colors.grey[700]
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your cart is empty",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          var item = cartItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    item['image'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.error_outline, 
                                          color: Colors.white54
                                        ),
                                      ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "₹${item['price']}",
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[850],
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove, 
                                                      size: 18, 
                                                      color: Colors.white
                                                    ),
                                                    onPressed: () {
                                                      if (item['quantity'] > 1) {
                                                        updateCartQuantity(
                                                          item['cart_id'],
                                                          item['quantity'] - 1
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  Text(
                                                    item['quantity'].toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add, 
                                                      size: 18, 
                                                      color: Colors.white
                                                    ),
                                                    onPressed: () {
                                                      updateCartQuantity(
                                                        item['cart_id'],
                                                        item['quantity'] + 1
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                              onPressed: () {
                                                deleteCartItem(item['cart_id']);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (cartItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total Amount:",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "₹${getTotalPrice().toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: confirmOrder,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Proceed to Payment",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
