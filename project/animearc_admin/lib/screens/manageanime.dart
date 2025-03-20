import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  PlatformFile? pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchGenres();
    fetchAnime();
  }

  Future<void> fetchGenres() async {
    try {
      final response = await Supabase.instance.client.from('tbl_genre').select();
      if (mounted) {
        setState(() => genreList = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      print("Error fetching genres: $e");
    }
  }

  Future<void> fetchAnime() async {
    try {
      final response = await Supabase.instance.client.from('tbl_anime').select('*,tbl_genre(*)');
      if (mounted) {
        setState(() => animeList = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      print("Error fetching anime: $e");
    }
  }

  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null) {
      setState(() => pickedImage = result.files.first);
    }
  }

  Future<String?> uploadPoster() async {
    if (pickedImage == null) return null;
    try {
      final fileName = "anime_${DateTime.now().millisecondsSinceEpoch}.${pickedImage!.name.split('.').last}";
      await Supabase.instance.client.storage.from('anime').uploadBinary(fileName, pickedImage!.bytes!);
      return Supabase.instance.client.storage.from('anime').getPublicUrl(fileName);
    } catch (e) {
      print("Error uploading poster: $e");
      return null;
    }
  }

  Future<void> addAnime() async {
    if (animeController.text.trim().isEmpty || _selectedGenre == null) return;
    setState(() => _isLoading = true);
    try {
      String? posterUrl = await uploadPoster();
      await Supabase.instance.client.from('tbl_anime').insert({
        'anime_name': animeController.text,
        'genre_id': _selectedGenre,
        'anime_poster': posterUrl,
      });
      animeController.clear();
      pickedImage = null;
      fetchAnime();
    } catch (e) {
      print("Error adding anime: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> updateAnimePoster(int animeId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      PlatformFile newImage = result.files.first;
      try {
        final fileName = "anime_${DateTime.now().millisecondsSinceEpoch}.${newImage.name.split('.').last}";
        await Supabase.instance.client.storage.from('anime').uploadBinary(fileName, newImage.bytes!);
        String newPosterUrl = Supabase.instance.client.storage.from('anime').getPublicUrl(fileName);
        await Supabase.instance.client.from('tbl_anime').update({'anime_poster': newPosterUrl}).eq('anime_id', animeId);
        fetchAnime();
      } catch (e) {
        print("Error updating anime poster: $e");
      }
    }
  }

  Future<void> deleteAnime(int animeId) async {
    try {
      await Supabase.instance.client.from('tbl_anime').delete().eq('anime_id', animeId);
      fetchAnime();
    } catch (e) {
      print("Error deleting anime: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Manage Anime", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.indigo)),
            ElevatedButton(
              onPressed: () => setState(() => _isFormVisible = !_isFormVisible),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormVisible ? Colors.redAccent : Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_isFormVisible ? "Cancel" : "Add Anime", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        if (_isFormVisible)
          Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedGenre,
                    onChanged: (value) => setState(() => _selectedGenre = value),
                    items: genreList.map((genre) => DropdownMenuItem(
                        value: genre['genre_id'].toString(),
                        child: Text(genre['genre_name']),
                      )).toList(),
                    decoration: InputDecoration(labelText: "Select Genre", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: animeController,
                    decoration: InputDecoration(labelText: "Anime Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: handleImagePick,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(12)),
                      child: pickedImage == null ? const Icon(Icons.add_a_photo, size: 50) : Image.memory(Uint8List.fromList(pickedImage!.bytes!), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : addAnime,
                    child: _isLoading ? const CircularProgressIndicator() : const Text("Add Anime"),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: anime['anime_poster'] != null
                      ? Image.network(anime['anime_poster'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                  title: Text(anime['anime_name']),
                  subtitle: Text("Genre: ${anime['tbl_genre']['genre_name']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => updateAnimePoster(anime['anime_id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteAnime(anime['anime_id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
