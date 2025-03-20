import 'package:animearc_admin/main.dart';
import 'package:flutter/material.dart';

class ManageAnime extends StatefulWidget {
  const ManageAnime({super.key});

  @override
  State<ManageAnime> createState() => _ManageAnimeState();
}

class _ManageAnimeState extends State<ManageAnime> {
  bool _isFormVisible = false;
  List<Map<String, dynamic>> animeList = [];
  List<Map<String, dynamic>> genreList = [];
  final TextEditingController animeController = TextEditingController();
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    fetchGenres();
    fetchAnime();
  }

  Future<void> fetchGenres() async {
    try {
      final response = await supabase.from('tbl_genre').select();
      setState(() => genreList = response);
    } catch (e) {
      print("Error fetching genres: $e");
    }
  }

  Future<void> fetchAnime() async {
    try {
      final response = await supabase.from('tbl_anime').select('*,tbl_genre(*)');
      setState(() => animeList = response);
    } catch (e) {
      print("Error fetching anime: $e");
    }
  }

  Future<void> addAnime() async {
    if (animeController.text.trim().isEmpty || _selectedGenre == null) return;
    try {
      await supabase.from('tbl_anime').insert({
        'anime_name': animeController.text,
        'genre_id': _selectedGenre,
      });
      animeController.clear();
      fetchAnime();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anime added successfully!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error adding anime: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding anime: $e", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteAnime(int animeId) async {
    try {
      await supabase.from('tbl_anime').delete().eq('anime_id', animeId);
      fetchAnime();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anime deleted successfully!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error deleting anime: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting anime: $e", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0), // Increased padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage Anime", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.indigo)), // Larger, bolder title
              ElevatedButton.icon(
                onPressed: () => setState(() => _isFormVisible = !_isFormVisible),
                icon: Icon(_isFormVisible ? Icons.cancel : Icons.add, color: Colors.white), // White icons
                label: Text(_isFormVisible ? "Cancel" : "Add Anime", style: const TextStyle(color: Colors.white)), // White text
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormVisible ? Colors.redAccent : Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isFormVisible
                ? Card(
                    elevation: 8, // Increased elevation for a more pronounced effect
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Increased padding inside card
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedGenre,
                            onChanged: (value) => setState(() => _selectedGenre = value),
                            items: genreList.map((genre) {
                              return DropdownMenuItem(
                                value: genre['genre_id'].toString(),
                                child: Text(genre['genre_name']),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              labelText: "Select Genre",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100], // Slightly filled background for input fields
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: animeController,
                            decoration: InputDecoration(
                              labelText: "Anime Name",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: addAnime,
                            child: const Text("Add Anime", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: animeList.isEmpty
                ? const Center(child: Text("No Anime Available", style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.grey)))
                : ListView.builder(
                    itemCount: animeList.length,
                    itemBuilder: (context, index) {
                      final anime = animeList[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8), // Added margin for spacing
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(anime['anime_name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          subtitle: Text("Genre: ${anime['tbl_genre']['genre_name']}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteAnime(anime['anime_id']),
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