import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final supabase = Supabase.instance.client;
  final TextEditingController stockController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  int totalStock = 0;
  List<Map<String, dynamic>> stockHistory = [];
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.product['product_name'] ?? '';
    priceController.text = widget.product['product_price']?.toString() ?? '';
    descController.text = widget.product['product_description'] ?? '';
    fetchStockHistory();
  }

  /// Fetch stock history and calculate total stock
  Future<void> fetchStockHistory() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('tbl_stock')
          .select('stock_qty, stock_date')
          .eq('product_id', widget.product['product_id'])
          .order('stock_date', ascending: false);

      int calculatedTotalStock =
          response.fold(0, (sum, stock) => sum + (stock['stock_qty'] as int));

      setState(() {
        stockHistory = List<Map<String, dynamic>>.from(response);
        totalStock = calculatedTotalStock;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching stock history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching stock history: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Update product details
  Future<void> updateProduct() async {
    setState(() => isUpdating = true);
    
    try {
      // Parse price to double - this handles numeric conversion
      double? price = double.tryParse(priceController.text.trim());
      if (price == null) {
        throw Exception("Invalid price format");
      }
      
      // Create update data with correct types
      final updateData = {
        'product_name': nameController.text.trim(),
        'product_price': price, // Send as double/numeric
        'product_description': descController.text.trim(),
      };
      
      // Update the product
      await supabase
          .from('tbl_product')
          .update(updateData)
          .eq('product_id', widget.product['product_id']);
      
      // Update the local widget product data to reflect changes
      setState(() {
        widget.product['product_name'] = nameController.text.trim();
        widget.product['product_price'] = price;
        widget.product['product_description'] = descController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error updating product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating product: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  /// Show edit product dialog
  void showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Product Name",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: "Price",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    prefixText: "\$", // Add dollar sign prefix
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            isUpdating
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      updateProduct();
                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
          ],
        );
      },
    );
  }

  /// Add or reduce stock function
  void showStockDialog(bool isAdding) {
    stockController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAdding ? "Add Stock" : "Reduce Stock"),
          content: TextField(
            controller: stockController,
            decoration: const InputDecoration(
              labelText: "Enter stock quantity",
              hintText: "e.g. 10",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                int? qty = int.tryParse(stockController.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Invalid stock quantity!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                updateStock(isAdding ? qty : -qty);
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  /// Update stock in database
  Future<void> updateStock(int qty) async {
    try {
      if (qty < 0 && (totalStock + qty) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Not enough stock available!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await supabase.from('tbl_stock').insert({
        'product_id': widget.product['product_id'],
        'stock_qty': qty,
        'stock_date': DateTime.now().toIso8601String(),
      });

      fetchStockHistory(); // Refresh stock details
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

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: showEditDialog,
            tooltip: "Edit Product",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchStockHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero section with image and gradient overlay
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.product['product_image'] ?? '',
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 80, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Product details card
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name and price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.product['product_name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "\$${widget.product['product_price'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Description
                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product['product_description'] ?? 'No description available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Stock information
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Text(
                                          "Current Stock",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          totalStock.toString(),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: totalStock > 10
                                                ? Colors.green
                                                : totalStock > 0
                                                    ? Colors.orange
                                                    : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => showStockDialog(true),
                                        icon: const Icon(Icons.add),
                                        label: const Text("Add"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => showStockDialog(false),
                                        icon: const Icon(Icons.remove),
                                        label: const Text("Remove"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Stock history
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Stock History",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: fetchStockHistory,
                                tooltip: "Refresh history",
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Stock history list
                          stockHistory.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text("No stock history available"),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: stockHistory.length,
                                  itemBuilder: (context, index) {
                                    final stock = stockHistory[index];
                                    final isPositive = stock['stock_qty'] > 0;
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 1,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isPositive ? Colors.green[100] : Colors.red[100],
                                          child: Icon(
                                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                            color: isPositive ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        title: Text(
                                          "${isPositive ? '+' : ''}${stock['stock_qty']} units",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isPositive ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        subtitle: Text(
                                          formatDate(stock['stock_date']),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}