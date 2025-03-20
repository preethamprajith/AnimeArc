import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadAnimeVideo extends StatefulWidget {
  const UploadAnimeVideo({super.key});

  @override
  State<UploadAnimeVideo> createState() => _UploadAnimeVideoState();
}

class _UploadAnimeVideoState extends State<UploadAnimeVideo> {
  final TextEditingController _episodeController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();

  PlatformFile? pickedVideo;
  String? selectedAnimeId;
  String? selectedGenreId;
  List<Map<String, dynamic>> animeList = [];
  List<Map<String, dynamic>> genreList = [];
  List<Map<String, dynamic>> filteredAnimeList = [];

  @override
  void initState() {
    super.initState();
    fetchGenres();
    fetchAnimeList();
  }

  Future<void> fetchGenres() async {
    try {
      final response = await Supabase.instance.client.from('tbl_genre').select();
      setState(() {
        genreList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      showSnackbar("Error fetching genres", Colors.red);
    }
  }

  Future<void> fetchAnimeList() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_anime')
          .select('anime_id, anime_name, genre_id');
      setState(() {
        animeList = List<Map<String, dynamic>>.from(response);
        applyGenreFilter();
      });
    } catch (e) {
      showSnackbar("Error fetching anime list", Colors.red);
    }
  }

  void applyGenreFilter() {
    setState(() {
      filteredAnimeList = selectedGenreId == null
          ? animeList
          : animeList.where((anime) => anime['genre_id'].toString() == selectedGenreId).toList();
      selectedAnimeId = null; // Reset selection after filtering
    });
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        pickedVideo = result.files.first;
      });
    }
  }

  Future<String?> uploadVideoToSupabase() async {
    if (pickedVideo == null) return null;

    try {
      final bucketName = 'anime';
      final now = DateTime.now();
      final timestamp = DateFormat('dd-MM-yy-HH-mm-ss').format(now);
      final fileExtension = pickedVideo!.name.split('.').last;
      final fileName = "$timestamp.$fileExtension";

      await Supabase.instance.client.storage.from(bucketName).uploadBinary(
        fileName,
        pickedVideo!.bytes!,
      );

      return Supabase.instance.client.storage.from(bucketName).getPublicUrl(fileName);
    } catch (e) {
      showSnackbar("Error uploading video", Colors.red);
      return null;
    }
  }

  Future<void> insertAnimeVideo() async {
    if (pickedVideo == null || selectedAnimeId == null) {
      showSnackbar("Please select a video file and an anime!", Colors.red);
      return;
    }

    try {
      String? videoUrl = await uploadVideoToSupabase();
      if (videoUrl == null) {
        showSnackbar("Failed to upload video!", Colors.red);
        return;
      }

      await Supabase.instance.client.from("tbl_animefile").insert({
        'animefile_file': videoUrl,
        'animefile_episode': _episodeController.text.isNotEmpty ? _episodeController.text : "1",
        'animefile_season': _seasonController.text.isNotEmpty ? _seasonController.text : "1",
        'anime_id': int.parse(selectedAnimeId!),
      });

      // Reset Fields
      _episodeController.clear();
      _seasonController.clear();
      selectedAnimeId = null;
      pickedVideo = null;
      setState(() {});

      showSuccessDialog();
    } catch (e) {
      showSnackbar("Error inserting anime video: ${e.toString()}", Colors.red);
    }
  }

  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Anime Video Uploaded Successfully!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload Anime Video",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),

          buildInputField("Episode", _episodeController),
          buildInputField("Season", _seasonController),

          const SizedBox(height: 10),

          buildDropdown(
            "Select Genre",
            selectedGenreId,
            genreList.map((genre) => DropdownMenuItem<String>(
              value: genre['genre_id'].toString(),
              child: Text(genre['genre_name']),
            )).toList(),
            (value) {
              setState(() {
                selectedGenreId = value;
                applyGenreFilter();
              });
            },
          ),

          const SizedBox(height: 10),

          buildDropdown(
            "Select Anime",
            selectedAnimeId,
            filteredAnimeList.map((anime) => DropdownMenuItem<String>(
              value: anime['anime_id'].toString(),
              child: Text(anime['anime_name']),
            )).toList(),
            (value) {
              setState(() {
                selectedAnimeId = value;
              });
            },
          ),

          const SizedBox(height: 10),

          buildFilePicker(),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              onPressed: insertAnimeVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Upload",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget buildDropdown(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget buildFilePicker() {
    return ListTile(
      title: Text(pickedVideo != null ? pickedVideo!.name : "Upload Video File"),
      trailing: IconButton(icon: const Icon(Icons.video_file, color: Colors.blue), onPressed: pickVideo),
    );
  }
}
