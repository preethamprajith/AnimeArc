import 'package:animearc_admin/main.dart';
import 'package:flutter/material.dart';

class ManageGenre extends StatefulWidget {
  const ManageGenre({super.key});

  @override
  State<ManageGenre> createState() => _ManageGenreState();
}

class _ManageGenreState extends State<ManageGenre> {
  bool _isFormVisible = false;
  List<Map<String, dynamic>> genreList = [];
  final TextEditingController genreController = TextEditingController();

  Future<void> genreSubmit() async {
    try {
      String genre = genreController.text.trim();
      if (genre.isEmpty) return;
      await supabase.from('tbl_genre').insert({'genre_name': genre});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Genre Added Successfully'),
          backgroundColor: Colors.green,
        ),
      );
      genreController.clear();
      fetchGenres();
    } catch (e) {
      print("Error adding genre: $e");
    }
  }

  Future<void> fetchGenres() async {
    try {
      final response = await supabase.from('tbl_genre').select();
      setState(() {
        genreList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching genres: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenres();
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
              Text(
                "Manage Genres",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isFormVisible = !_isFormVisible);
                },
                label: Text(_isFormVisible ? "Cancel" : "Add Genre"),
                icon: Icon(_isFormVisible ? Icons.cancel : Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: _isFormVisible
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: genreController,
                            decoration: InputDecoration(
                              labelText: "Genre Name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.category),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: genreSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrangeAccent,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Add Genre",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: genreList.isEmpty
                ? Center(
                    child: Text(
                      "No Genres Available",
                      style:
                          TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    itemCount: genreList.length,
                    itemBuilder: (context, index) {
                      final genre = genreList[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            genre['genre_name'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await supabase
                                  .from('tbl_genre')
                                  .delete()
                                  .eq('genre_id', genre['genre_id']);
                              fetchGenres();
                            },
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
