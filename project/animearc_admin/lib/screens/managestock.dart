import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Managestock extends StatefulWidget {
  const Managestock({super.key});

  @override
  State<Managestock> createState() => _ManagestockState();
}

class _ManagestockState extends State<Managestock> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> stockData = [];

  @override
  void initState() {
    super.initState();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    try {
      final response = await supabase
          .from('tbl_stock')
          .select('stock_id, stock_qty, stock_date, tbl_product(product_id, product_name, product_image)')
          .order('stock_date', ascending: false);

      setState(() {
        stockData = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching stock data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Stock"),
        backgroundColor:const Color.fromARGB(255, 235, 158, 50),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: stockData.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: stockData.length,
                itemBuilder: (context, index) {
                  final stock = stockData[index];

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: stock['tbl_product']['product_image'] != null
                          ? Image.network(
                              stock['tbl_product']['product_image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      title: Text(
                        stock['tbl_product']['product_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            "Stock Quantity: ${stock['stock_qty']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Date: ${stock['stock_date'].toString().split(' ')[0]}",
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editStock(stock),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteStock(stock['stock_id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addStock,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ========================== ADD / UPDATE STOCK ==========================
  void addStock() async {
    final products = await supabase.from('tbl_product').select('product_id, product_name');
    String? selectedProduct;
    TextEditingController qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Stock"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField(
                items: products.map<DropdownMenuItem<String>>((product) {
                  return DropdownMenuItem(
                    value: product['product_id'].toString(),
                    child: Text(product['product_name']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedProduct = value as String?;
                },
                decoration: const InputDecoration(labelText: "Select Product"),
              ),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Enter Quantity"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProduct != null && qtyController.text.isNotEmpty) {
                  await supabase.from('tbl_stock').insert({
                    'product_id': int.parse(selectedProduct!),
                    'stock_qty': int.parse(qtyController.text),
                    'stock_date': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(context);
                  fetchStockData();
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void editStock(Map<String, dynamic> stock) {
    TextEditingController qtyController = TextEditingController(text: stock['stock_qty'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Stock Quantity"),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter New Quantity"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await supabase
                    .from('tbl_stock')
                    .update({'stock_qty': int.parse(qtyController.text)})
                    .eq('stock_id', stock['stock_id']);
                Navigator.pop(context);
                fetchStockData();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteStock(int stockId) async {
    await supabase.from('tbl_stock').delete().eq('stock_id', stockId);
    fetchStockData();
  }
}