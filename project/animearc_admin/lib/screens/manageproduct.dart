import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ManageProduct extends StatefulWidget {
  const ManageProduct({super.key});

  @override
  _ManageProductState createState() => _ManageProductState();
}

class _ManageProductState extends State<ManageProduct> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String? _selectedCategory;
  String? _selectedAnime;
  bool _isLoading = false; // Loading state

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> animes = [];

  PlatformFile? pickedImage;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAnimes();
  }

  Future<void> _fetchCategories() async {
    final response = await Supabase.instance.client.from('tbl_category').select();
    if (mounted) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _fetchAnimes() async {
    final response = await Supabase.instance.client.from('tbl_anime').select();
    if (mounted) {
      setState(() {
        animes = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        pickedImage = result.files.first;
      });
    }
  }

  Future<String?> photoUpload() async {
    try {
      if (pickedImage == null) return null;

      final bucketName = 'product';
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileExtension = pickedImage!.name.split('.').last;
      final fileName = "$timestamp.$fileExtension";
      final filePath = fileName;

      await Supabase.instance.client.storage.from(bucketName).uploadBinary(
            filePath,
            pickedImage!.bytes!,
          );

      return Supabase.instance.client.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      print("Error photo upload: $e");
      return null;
    }
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedAnime == null ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? url = await photoUpload();

      final response = await Supabase.instance.client.from('tbl_product').insert({
        'product_name': _nameController.text,
        'category_id': _selectedCategory,
        'anime_id': _selectedAnime,
        'product_price': double.tryParse(_priceController.text) ?? 0.0,
        'product_description': _detailsController.text,
        'product_image': url,
      }).select('product_id').single(); // Get the newly inserted product's ID

      if (response != null && response['product_id'] != null) {
        await Supabase.instance.client.from('tbl_stock').insert({
          'product_id': response['product_id'],
          'stock_qty': 0, // Default stock quantity
          'stock_date': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product inserted successfully!"), backgroundColor: Colors.green),
      );

      _nameController.clear();
      _priceController.clear();
      _detailsController.clear();
      setState(() {
        pickedImage = null;
        _selectedCategory = null;
        _selectedAnime = null;
        _isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error inserting product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error inserting product: $e"), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Products"),
        backgroundColor: const Color.fromARGB(255, 214, 147, 38),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Product",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 64, 50, 214)),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Product Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField(
                  value: _selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category['category_id'].toString(),
                      child: Text(category['category_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value as String?;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField(
                  value: _selectedAnime,
                  items: animes.map((anime) {
                    return DropdownMenuItem(
                      value: anime['anime_id'].toString(),
                      child: Text(anime['anime_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAnime = value as String?;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Anime",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Price",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _detailsController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                Center(
                  child: InkWell(
                    onTap: handleImagePick,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromARGB(255, 53, 61, 214), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: pickedImage == null
                          ? const Icon(Icons.add_a_photo, color: Color.fromARGB(255, 19, 28, 161), size: 50)
                          : Image.memory(Uint8List.fromList(pickedImage!.bytes!), fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Add Product", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
