import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/pay.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
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
      setState(() => bid = bookingId);

      final cartResponse = await supabase
          .from('tbl_cart')
          .select('*')
          .eq('booking_id', bookingId)
          .eq('cart_status', '1');

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
      final response = await supabase
          .from('tbl_cart')
          .update({'cart_status': 1})
          .eq('booking_id', bid!)
          .select();

      if (response.isEmpty) {
        throw Exception("Failed to update order status.");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully!')),
      );

      fetchCartItems();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Pay(bid: bid!)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  double getTotalPrice() {
    return cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Cart")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(child: Text("Your cart is empty"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          var item = cartItems[index];
                          return Container(
                            margin: EdgeInsets.all(8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(item['image'], width: 80, height: 80, fit: BoxFit.cover),
                                SizedBox(height: 8),
                                Text(item['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("\$${item['price']} per item"),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: 18),
                                          onPressed: () {
                                            if (item['quantity'] > 1) {
                                              updateCartQuantity(item['cart_id'], item['quantity'] - 1);
                                            }
                                          },
                                        ),
                                        Text(item['quantity'].toString(), style: TextStyle(fontSize: 14)),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 18),
                                          onPressed: () {
                                            updateCartQuantity(item['cart_id'], item['quantity'] + 1);
                                          },
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        deleteCartItem(item['cart_id']);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: confirmOrder, child: Text("Place order"))),
                  ],
                ),
    );
  }
}
