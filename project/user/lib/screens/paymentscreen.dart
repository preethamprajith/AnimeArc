import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/success.dart';


class PaymentScreen extends StatefulWidget {
  final int bid;
  final double total;
  const PaymentScreen({super.key, required this.bid, required this.total});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _confirmOrder() async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields correctly!")),
      );
      return;
    }

    try {
      // Get cart items first to calculate stock changes
      final cartItems = await supabase
          .from('tbl_cart')
          .select('''
            product_id, 
            cart_qty,
            tbl_product (
              product_name,
              product_price
            )
          ''')
          .eq('booking_id', widget.bid)
          .eq('cart_status', '0');

      // Process each item and update stock
      for (var item in cartItems) {
        final productId = item['product_id'];
        final quantity = int.tryParse(item['cart_qty'].toString()) ?? 0;
        var remainingQty = quantity;

        // Get available stock entries
        final stockEntries = await supabase
            .from('tbl_stock')
            .select('stock_id, stock_qty')
            .eq('product_id', productId)
            .gt('stock_qty', '0')
            .order('stock_date', ascending: true);

        // Update stock quantities
        for (var stock in stockEntries) {
          if (remainingQty <= 0) break;

          final stockId = stock['stock_id'];
          final currentStock = int.tryParse(stock['stock_qty'].toString()) ?? 0;
          final deduction = remainingQty > currentStock ? currentStock : remainingQty;
          final newStock = currentStock - deduction;

          await supabase
              .from('tbl_stock')
              .update({'stock_qty': newStock.toString()})
              .eq('stock_id', stockId);

          remainingQty -= deduction;
        }

        if (remainingQty > 0) {
          throw Exception('Insufficient stock for ${item['tbl_product']['product_name']}');
        }
      }

      // Update booking with final details
      final now = DateTime.now().toIso8601String();
      await supabase
          .from('tbl_booking')
          .update({
            'booking_status': '1',  // Confirmed status
            'booking_amount': widget.total,
            'booking_data': now,
            'booking_trackid': 'Processing', // Initial tracking status
          })
          .eq('booking_id', widget.bid);

      // Update cart items status
      await supabase
          .from('tbl_cart')
          .update({
            'cart_status': '1'  // Confirmed status
          })
          .eq('booking_id', widget.bid);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
        );
      }
    } catch (e) {
      print('Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment"), backgroundColor: Colors.deepPurple),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CreditCardWidget(
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName,
                cvvCode: cvvCode,
                showBackView: isCvvFocused,
                onCreditCardWidgetChange: (creditCardBrand) {},
                isHolderNameVisible: true,
                enableFloatingCard: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CreditCardForm(
                        cardNumber: cardNumber,
                        expiryDate: expiryDate,
                        cardHolderName: cardHolderName,
                        cvvCode: cvvCode,
                        isHolderNameVisible: true,
                        onCreditCardModelChange: (creditCardModel) {
                          setState(() {
                            cardNumber = creditCardModel.cardNumber;
                            expiryDate = creditCardModel.expiryDate;
                            cardHolderName = creditCardModel.cardHolderName;
                            cvvCode = creditCardModel.cvvCode;
                            isCvvFocused = creditCardModel.isCvvFocused;
                          });
                        },
                        formKey: formKey,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                        onPressed: _confirmOrder,
                        child: const Text("Pay Now", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}