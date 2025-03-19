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
      await supabase
          .from('tbl_booking')
          .update({'booking_status': '2', 'booking_amount': widget.total})
          .match({'booking_id': widget.bid});
      await supabase
          .from('tbl_cart')
          .update({'cart_status': '2'})
          .match({'booking_id': widget.bid});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating order: $e")),
      );
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