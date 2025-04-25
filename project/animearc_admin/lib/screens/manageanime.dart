import 'dart:typed_data';
import 'package:animearc_admin/screens/manageanimefile.dart';
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
  final TextEditingController descriptionController = TextEditingController(); // Add this line
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
        'anime_description': descriptionController.text, // Add this line
        'genre_id': _selectedGenre,
        'anime_poster': posterUrl,
      });
      animeController.clear();
      descriptionController.clear(); // Add this line
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
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Anime'),
        content: const Text('This will delete all episodes and related data. Are you sure?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      final supabase = Supabase.instance.client;

      // 1. Get anime details for poster deletion
      final anime = await supabase
          .from('tbl_anime')
          .select('anime_poster')
          .eq('anime_id', animeId)
          .single();

      // 2. Get all episodes to delete their files
      final episodes = await supabase
          .from('tbl_animefile')
          .select('animefile_file') // Changed from animefile_video to animefile_file
          .eq('anime_id', animeId);

      // 3. Delete episode files from storage
      for (final episode in episodes) {
        if (episode['animefile_file'] != null) { // Changed from animefile_video to animefile_file
          try {
            final videoPath = episode['animefile_file'].toString().split('/').last; // Changed from animefile_video to animefile_file
            await supabase.storage.from('anime').remove(['anime_videos/$videoPath']); // Updated storage path
          } catch (e) {
            print('Error deleting episode file: $e');
          }
        }
      }

      // 4. Delete anime poster from storage
      if (anime['anime_poster'] != null) {
        try {
          final posterPath = anime['anime_poster'].toString().split('/').last;
          await supabase.storage.from('anime').remove([posterPath]);
        } catch (e) {
          print('Error deleting poster: $e');
        }
      }

      // 5. Get all products related to this anime
      final products = await supabase
          .from('tbl_product')
          .select('product_id')
          .eq('anime_id', animeId);

      // 6. For each product, delete related records in order
      for (final product in products) {
        final productId = product['product_id'];
        
        // Delete from cart first
        await supabase
            .from('tbl_cart')
            .delete()
            .eq('product_id', productId);
        
        // Delete from stock
        await supabase
            .from('tbl_stock')
            .delete()
            .eq('product_id', productId);
      }

      // 7. Now delete all products related to this anime
      await supabase
          .from('tbl_product')
          .delete()
          .eq('anime_id', animeId);

      // 8. Delete from tbl_review
      await supabase
          .from('tbl_review')
          .delete()
          .eq('anime_id', animeId);

      // 9. Delete from tbl_watchlist
      await supabase
          .from('tbl_watchlist')
          .delete()
          .eq('anime_id', animeId);

      // 10. Delete all episodes
      await supabase
          .from('tbl_animefile')
          .delete()
          .eq('anime_id', animeId);

      // 11. Finally delete the anime
      await supabase
          .from('tbl_anime')
          .delete()
          .eq('anime_id', animeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anime deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchAnime(); // Refresh the list
      }
    } catch (e) {
      print('Error deleting anime: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting anime: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  TextField( // Add this TextField
                    controller: descriptionController,
                    maxLines: 3, // Allow multiple lines for description
                    decoration: InputDecoration(
                      labelText: "Anime Description",
                      hintText: "Enter anime description...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      alignLabelWithHint: true, // Aligns label with the hint and text
                    ),
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
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => UploadAnimeVideo(animeId: anime['anime_id'],),));
                  },
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

  @override
  void dispose() {
    animeController.dispose();
    descriptionController.dispose(); // Add this line
    super.dispose();
  }
}
