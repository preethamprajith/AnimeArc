import 'package:animearc_admin/main.dart';
import 'package:flutter/material.dart';

class Managegenre extends StatefulWidget {
  const Managegenre({super.key});

  @override
  State<Managegenre> createState() => _ManagegenreState();
}

class _ManagegenreState extends State<Managegenre>
    with SingleTickerProviderStateMixin {
  
  bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController genreController = TextEditingController();
  Future<void> genreSubmit()  async {
    try {
      String genre = genreController.text;
      await supabase.from('tbl_genre').insert({
        'genre_name': genre,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'genre Added',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      print("Inserted");
      genreController.clear();
    } catch (e) {
      print("ERROR GENRE : $e");
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
              Text("Manage Genre"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                  
                },
                label: Text(_isFormVisible ? "Cancel" :"Add Genre"),
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
                      Text("Genre Form"),
                      Padding(
                        padding: const EdgeInsets.only(left: 400, right: 400),
                        child: TextFormField(
                          controller: genreController,
                          decoration: InputDecoration(
                            hintText: "GENRE",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ElevatedButton(
                          onPressed: () {
                            genreSubmit();
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
              child: Text("Genre Data"),
            ),
          )
        ],
      ),
    );
  }
}
