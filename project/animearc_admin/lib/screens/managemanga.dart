import 'dart:typed_data';
import 'package:animearc_admin/screens/manga_volume.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageManga extends StatefulWidget {
  const ManageManga({super.key});

  @override
  State<ManageManga> createState() => _ManageMangaState();
}

class _ManageMangaState extends State<ManageManga> {
  bool _isFormVisible = false;
  List<Map<String, dynamic>> mangaList = [];
  List<Map<String, dynamic>> genreList = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? _selectedGenre;
  PlatformFile? pickedCover;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchGenres();
    fetchManga();
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

  Future<void> fetchManga() async {
    try {
      final response = await Supabase.instance.client.from('tbl_manga').select('*,tbl_genre(*)');
      if (mounted) {
        setState(() => mangaList = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      print("Error fetching manga: $e");
    }
  }

  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null) {
      setState(() => pickedCover = result.files.first);
    }
  }

  Future<String?> uploadCover() async {
    if (pickedCover == null) return null;
    try {
      final fileName = "manga_${DateTime.now().millisecondsSinceEpoch}.${pickedCover!.name.split('.').last}";
      await Supabase.instance.client.storage.from('manga').uploadBinary(fileName, pickedCover!.bytes!);
      return Supabase.instance.client.storage.from('manga').getPublicUrl(fileName);
    } catch (e) {
      print("Error uploading cover: $e");
      return null;
    }
  }

  Future<void> addManga() async {
    if (titleController.text.trim().isEmpty || _selectedGenre == null) return;
    setState(() => _isLoading = true);
    try {
      String? coverUrl = await uploadCover();
      await Supabase.instance.client.from('tbl_manga').insert({
        'manga_title': titleController.text,
        'manga_author': authorController.text,
        'manga_description': descriptionController.text,
        'manga_cover': coverUrl,
        'genre_id': _selectedGenre,
      });
      titleController.clear();
      authorController.clear();
      descriptionController.clear();
      pickedCover = null;
      fetchManga();
    } catch (e) {
      print("Error adding manga: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> deleteManga(int mangaId) async {
    try {
      await Supabase.instance.client.from('tbl_manga').delete().eq('manga_id', mangaId);
      fetchManga();
    } catch (e) {
      print("Error deleting manga: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage Manga", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
              ElevatedButton(
                onPressed: () => setState(() => _isFormVisible = !_isFormVisible),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormVisible ? Colors.redAccent : Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_isFormVisible ? "Cancel" : "Add Manga", style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          if (_isFormVisible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
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
                          controller: titleController,
                          decoration: InputDecoration(labelText: "Manga Title", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: authorController,
                          decoration: InputDecoration(labelText: "Author", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(labelText: "Description", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            InkWell(
                              onTap: handleImagePick,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.purple, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: pickedCover == null
                                    ? const Icon(Icons.add_photo_alternate, size: 50)
                                    : Image.memory(Uint8List.fromList(pickedCover!.bytes!), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: handleImagePick,
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload Cover"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : addManga,
                          child: _isLoading ? const CircularProgressIndicator() : const Text("Add Manga"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: mangaList.length,
            itemBuilder: (context, index) {
              final manga = mangaList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: manga['manga_cover'] != null
                      ? Image.network(manga['manga_cover'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.menu_book),
                  title: Text(manga['manga_title'] ?? 'No Title'),
                  subtitle: Text("Author: ${manga['manga_author']}\nGenre: ${manga['tbl_genre']?['genre_name'] ?? ''}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteManga(manga['manga_id']),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=> ManageVolume(mangaId: manga['manga_id'],)));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: const Size(90, 36),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text("View Volume", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
