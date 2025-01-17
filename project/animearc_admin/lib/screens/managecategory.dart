import 'package:animearc_admin/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Managecategory extends StatefulWidget {
  const Managecategory({super.key});

  @override
  State<Managecategory> createState() => _ManagecategoryState();
}

class _ManagecategoryState extends State<Managecategory> 
  with SingleTickerProviderStateMixin{
     bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController categoryController = TextEditingController();
  Future<void> categorySubmit()  async {
    try {
      String category = categoryController.text;
      await supabase.from('tbl_category').insert({
        'category_name': category,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'category Added',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      print("Inserted");
      categoryController.clear();
    } catch (e) {
      print("ERROR category: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Manage category"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                  
                },
                label: Text(_isFormVisible ? "Cancel" :"Add category"),
                icon: Icon(_isFormVisible ? Icons.cancel :Icons.add ),
              )
            ],
          ),
          AnimatedSize(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            child: _isFormVisible
                ? Form(
                    child: Column(
                    children: [
                      Text("category Form"),
                      Padding(
                        padding: const EdgeInsets.only(left: 400, right: 400),
                        child: TextFormField(
                          controller: categoryController,
                          decoration: InputDecoration(
                            hintText: "CATEGORY",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ElevatedButton(
                          onPressed: () {
                            categorySubmit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 201, 132, 13),
                            padding: EdgeInsets.symmetric(
                                horizontal: 90, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20), 
                              side: BorderSide(
                                  color: Colors.orangeAccent,
                                  width: 2), 
                            ),
                            shadowColor: Colors.orangeAccent, 
                            elevation: 10, 
                          ),
                          child: Text(
                            "add",
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight:
                                  FontWeight.bold, 
                              color: const Color.fromARGB(240, 1, 1, 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ))
                : Container(),
          ),
          Container(
           
            child: Center(
              child: Text("category Data"),
            ),
          )
        ],
      ),
    );
  }
}