import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final TextEditingController stockController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productDescController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  int stockQty = 0;
  String stockDate = 'N/A';
  int stockId = 0;

  @override
  void initState() {
    super.initState();
    productNameController.text = widget.product['product_name'];
    productDescController.text = widget.product['product_description'];
    productPriceController.text = widget.product['product_price'].toString();
    _fetchStockDetails();
    _updateProductDetails();
  }

  Future<void> _fetchStockDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_stock')
          .select('stock_id, stock_qty, stock_date')
          .eq('product_id', widget.product['product_id'])
          .maybeSingle();

      if (response != null) {
        setState(() {
          stockId = response['stock_id'];
          stockQty = response['stock_qty'] ?? 0;
          stockDate = response['stock_date'] ?? 'N/A';
        });
      } else {
        setState(() {
          stockId = 0;
          stockQty = 0;
          stockDate = 'N/A';
        });
      }
    } catch (e) {
      print("Error fetching stock details: $e");
    }
  }

  /// Function to Update Product Details
 Future<void> _updateProductDetails() async {
  // Immediately update the product details in the UI.
  setState(() {
    widget.product['product_name'] = productNameController.text;
    widget.product['product_description'] = productDescController.text;
    widget.product['product_price'] =
        double.tryParse(productPriceController.text) ?? 0.0;
  });

  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Product details updated successfully!"),
      backgroundColor: Colors.green,
    ),
  );

  try {
    final response = await Supabase.instance.client.from('tbl_product').update({
      'product_name': productNameController.text,
      'product_description': productDescController.text,
      'product_price': double.tryParse(productPriceController.text) ?? 0.0,
    }).eq('product_id', widget.product['product_id']);

    // Ensure that the backend update was successful
    if (response != null) {
      // You can choose to keep this code as a confirmation, but the UI update already took place
    }
  } catch (e) {
    // If there's an error, revert the UI update and show an error message
    setState(() {
      // Revert to original data if update fails
      productNameController.text = widget.product['product_name'];
      productDescController.text = widget.product['product_description'];
      productPriceController.text = widget.product['product_price'].toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error updating product details: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  /// Function to Update or Add Stock
  Future<void> _updateStock({bool isAdding = true}) async {
    try {
      int enteredStock = int.tryParse(stockController.text) ?? 0;
      if (enteredStock > 0) {
        int updatedStock =
            isAdding ? (stockQty + enteredStock) : (stockQty - enteredStock);
        if (updatedStock < 0) updatedStock = 0;

        String currentDate = DateTime.now().toLocal().toString().split(' ')[0];

        if (stockId != 0) {
          // Update stock if stockId exists
          await Supabase.instance.client.from('tbl_stock').update({
            'stock_qty': updatedStock,
            'stock_date': currentDate,
          }).eq('stock_id', stockId);
        } else {
          // Insert new stock if stockId is null
          final response = await Supabase.instance.client
              .from('tbl_stock')
              .insert({
                'product_id': widget.product['product_id'],
                'stock_qty': updatedStock,
                'stock_date': currentDate,
              })
              .select('stock_id')
              .maybeSingle();

          if (response != null) {
            stockId = response['stock_id'];
          }
        }

        _fetchStockDetails();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdding
                ? "Stock added successfully!"
                : "Stock updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating stock: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating stock: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Function to Show Product Edit Dialog
  void _showProductEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Product Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productNameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: productDescController,
                decoration:
                    const InputDecoration(labelText: "Product Description"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: productPriceController,
                decoration: const InputDecoration(labelText: "Product Price"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _updateProductDetails,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// Function to Show Stock Add Dialog
  void _showStockAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Stock Quantity"),
          content: TextFormField(
            controller: stockController,
            decoration:
                const InputDecoration(hintText: "Enter quantity to add"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _updateStock(isAdding: true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Function to Show Stock Reduce Dialog
  void _showStockReduceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reduce Stock Quantity"),
          content: TextFormField(
            controller: stockController,
            decoration:
                const InputDecoration(hintText: "Enter quantity to reduce"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _updateStock(isAdding: false),
              child: const Text('Reduce'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showProductEditDialog,
            tooltip: 'Edit Product',
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _showStockReduceDialog,
            tooltip: 'Reduce Stock',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.product['product_image'] ??
                            'https://via.placeholder.com/300',
                        width: double.infinity,
                        height: 400,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.broken_image, size: 100));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
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
                            style: const TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Price: \$${widget.product['product_price'] ?? '0.00'}",
                            style: const TextStyle(
                                fontSize: 24, color: Colors.green),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Description:",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.product['product_description'] ??
                                'No description available',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
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
        onPressed: _showStockAddDialog, // Show dialog to add stock
        child: const Icon(Icons.add),
      ),
    );
  }
}
