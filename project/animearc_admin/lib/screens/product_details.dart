import 'package:flutter/material.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final TextEditingController stockController = TextEditingController();
  late int stockQty;
  late String stockDate;

  @override
  void initState() {
    super.initState();
    stockQty = widget.product['stock_qty'] ?? 0;
    stockDate = widget.product['stock_date'] ?? 'N/A';
  }

  void submitStock() {
    try {
      int newStock = int.tryParse(stockController.text) ?? 0;
      if (newStock > 0) {
        setState(() {
          stockQty += newStock;
          stockDate = DateTime.now().toLocal().toString().split(' ')[0]; // Updates to current date
        });
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void addStock() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Stock'),
          content: TextFormField(
            controller: stockController,
            decoration: const InputDecoration(hintText: 'Enter the quantity'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: submitStock,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side - Product Image (Smaller)
                  Expanded(
                    flex: 2, // Takes less space
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.product['product_image'] ?? 'https://via.placeholder.com/300',
                        width: double.infinity,
                        height: 400,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, size: 100));
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Right Side - Product Details (Bigger)
                  Expanded(
                    flex: 4, // Takes more space
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product['product_name'] ?? "No Name",
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Price: \$${widget.product['product_price'] ?? '0.00'}",
                            style: const TextStyle(fontSize: 24, color: Colors.green),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Description:",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.product['product_description'] ?? 'No description available',
                            style: const TextStyle(fontSize: 18, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bottom Section - Stock Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stock Quantity: $stockQty",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Last Updated: $stockDate",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addStock,
        child: const Icon(Icons.add),
        tooltip: 'Add Stock',
      ),
    );
  }
}
