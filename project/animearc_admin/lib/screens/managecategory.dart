import 'package:animearc_admin/main.dart';
import 'package:flutter/material.dart';

class ManageCategory extends StatefulWidget {
  const ManageCategory({super.key});

  @override
  State<ManageCategory> createState() => _ManageCategoryState();
}

class _ManageCategoryState extends State<ManageCategory> {
  bool _isFormVisible = false;
  List<Map<String, dynamic>> categoryList = [];
  final TextEditingController categoryController = TextEditingController();

  Future<void> categorySubmit() async {
    try {
      String category = categoryController.text.trim();
      if (category.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category name cannot be empty'), backgroundColor: Colors.red),
        );
        return;
      }

      // Insert into Supabase
      await supabase.from('tbl_category').insert({'category_name': category});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category Added Successfully'), backgroundColor: Colors.green),
      );

      categoryController.clear();
      fetchCategories();
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await supabase.from('tbl_category').select();
      setState(() {
        categoryList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await supabase.from("tbl_category").delete().eq("category_id", categoryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category Deleted'), backgroundColor: Colors.red),
      );
      fetchCategories();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage Categories", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isFormVisible = !_isFormVisible);
                },
                label: Text(_isFormVisible ? "Cancel" : "Add Category"),
                icon: Icon(_isFormVisible ? Icons.cancel : Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Animated Form
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isFormVisible
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: categoryController,
                            decoration: InputDecoration(
                              labelText: "Category Name",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.category),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: categorySubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrangeAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Add Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Categories List
          Expanded(
            child: categoryList.isEmpty
                ? const Center(
                    child: Text("No Categories Available", style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
                  )
                : ListView.builder(
                    itemCount: categoryList.length,
                    itemBuilder: (context, index) {
                      final category = categoryList[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(category['category_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCategory(category['category_id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
