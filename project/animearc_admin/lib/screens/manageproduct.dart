import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../main.dart';

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

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> animes = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAnimes();
  }

  PlatformFile? pickedImage;

  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Only single file upload
    );
    if (result != null) {
      setState(() {
        pickedImage = result.files.first;
      });
    }
  }

  Future<String?> photoUpload() async {
    try {
      final bucketName = 'product'; // Replace with your bucket name
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileExtension =
          pickedImage!.name.split('.').last; // Get the file extension
      final fileName =
          "${timestamp}.${fileExtension}"; // New file name with timestamp
      final filePath = fileName;

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            pickedImage!.bytes!, // Use file.bytes for Flutter Web
          );

      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print("Error photo upload: $e");
      return null;
    }
  }

  Future<void> _fetchCategories() async {
    final response =
        await Supabase.instance.client.from('tbl_category').select();
    if (mounted) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _fetchAnimes() async {
    final response =
        await Supabase.instance.client.from('tbl_anime').select();
    if (mounted) {
      setState(() {
        animes = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _submitProduct() async {
    try {
      String? url = await photoUpload();

      await Supabase.instance.client.from('tbl_product').insert({
        'product_name': _nameController.text,
        'category_id': _selectedCategory,
        'anime_id': _selectedAnime,
        'product_price': double.tryParse(_priceController.text) ?? 0.0,
        'product_description': _detailsController.text,
        'product_image': url,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product inserted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error inserting product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error inserting product: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "add product",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Product Name"),
                ),
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
                  decoration: const InputDecoration(labelText: "Category"),
                ),
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
                  decoration: const InputDecoration(labelText: "Anime"),
                ),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price"),
                ),
                TextField(
                  controller: _detailsController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  width: 120,
                  child: pickedImage == null
                      ? GestureDetector(
                          onTap: handleImagePick,
                          child: Icon(
                            Icons.add_a_photo,
                            color: Color(0xFF0277BD),
                            size: 50,
                          ),
                        )
                      : GestureDetector(
                          onTap: handleImagePick,
                          child: ClipRRect(
                            child: pickedImage!.bytes != null
                                ? Image.memory(
                                    Uint8List.fromList(
                                        pickedImage!.bytes!), // For web
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(pickedImage!
                                        .path!), // For mobile/desktop
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _submitProduct,
                  child: const Text("Add Product"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
