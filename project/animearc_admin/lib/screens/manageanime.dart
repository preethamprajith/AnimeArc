import 'package:animearc_admin/main.dart';
import 'package:flutter/material.dart';

class Manageanime extends StatefulWidget {
  const Manageanime({super.key});

  @override
  State<Manageanime> createState() => _ManageanimeState();
}

class _ManageanimeState extends State<Manageanime>
    with SingleTickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  bool _isFormVisible = false;
  List<Map<String, dynamic>> genreList = [];
  List<Map<String, dynamic>> animeList = [];
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController animeController = TextEditingController();
  Future<void> manageanime() async {
    try {
      String anime = animeController.text;
      await supabase
          .from("tbl_anime")
          .insert({'anime_name': anime, 'genre_id': _selectedGenre});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'anime added',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      print("Inserted");
      animeController.clear();
      fetchAnime();
    } catch (e) {
      print("error for adding anime: $e");
    }
  }

  Future<void> fetchgenre() async {
    try {
      final response = await supabase.from('tbl_genre').select();
      print(response);
      if (response.isNotEmpty) {
        setState(() {
          genreList = response;
        });
      }
    } catch (e) {
      print("Error fetching genre: $e");
    }
  }

  Future<void> fetchAnime() async {
    try {
      final response =
          await supabase.from("tbl_anime").select('*,tbl_genre(*)');
      print("response: $response");
      if (response.isNotEmpty) {
        setState(() {
          animeList = response;
        });
      }
    } catch (e) {
      print("ERROR FETCHING ANIME DATA: $e");
    }
  }

  void display() {
    print(animeList);
  }

  @override
  void initState() {
    super.initState();
    fetchAnime();
    fetchgenre();
  }

  String _selectedGenre = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage anime"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label: Text(_isFormVisible ? "Cancel" : "Add anime"),
                icon: Icon(_isFormVisible ? Icons.cancel : Icons.add),
              )
            ],
          ),
          AnimatedSize(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            child: _isFormVisible
                ? Form(
                    key: _formkey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "anime Form",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGenre.isNotEmpty
                                      ? _selectedGenre
                                      : null,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedGenre = newValue!;
                                    });
                                  },
                                  items: genreList.map((genre) {
                                    print("Genre: $genre");
                                    return DropdownMenuItem<String>(
                                      value: (genre['genre_id']).toString(),
                                      child: Text(genre['genre_name'] ?? ""),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: animeController,
                                decoration: const InputDecoration(
                                  labelText: "anime  Name",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                manageanime();
                              },
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          DataTable(
            columns: [
              DataColumn(label: Text("Sl.No")),
              
              DataColumn(label: Text("genre")),
              DataColumn(label: Text("anime")),
              DataColumn(label: Text("DElete")),
            ],
            rows: animeList.asMap().entries.map((entry) {
              // print(entry.value);
              return DataRow(cells: [
                DataCell(Text((entry.key + 1).toString())),
               
                DataCell(Text(
                    entry.value['tbl_genre']['genre_name'])), // serial number
                DataCell(Text(entry.value['anime_name'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // _deleteAcademicYear(docId); // Delete academic year
                    },
                  ),
                ),
              ]);
            }).toList(),
          )
        ],
      ),
    );
  }
}
