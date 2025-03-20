import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  List<Map<String, dynamic>> genres = [];
  Map<String, List<Map<String, dynamic>>> animeByGenre = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGenresWithAnime();
  }

  Future<void> fetchGenresWithAnime() async {
    try {
      final genreResponse = await Supabase.instance.client.from('tbl_genre').select('*');
      final animeResponse = await Supabase.instance.client.from('tbl_anime').select('*, tbl_genre(genre_name)');

      setState(() {
        genres = List<Map<String, dynamic>>.from(genreResponse);
        animeByGenre = {};

        for (var anime in animeResponse) {
          String genreName = anime['tbl_genre']['genre_name'] ?? "Unknown";
          if (!animeByGenre.containsKey(genreName)) {
            animeByGenre[genreName] = [];
          }
          animeByGenre[genreName]!.add(anime);
        }

        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Animearc', style: TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.orange), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search, color: Colors.orange), onPressed: () {}),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: animeByGenre.entries.map((entry) {
                  return _buildGenreSection(entry.key, entry.value);
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildGenreSection(String genreName, List<Map<String, dynamic>> animeList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(genreName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              return _buildAnimeCard(animeList[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              anime['anime_poster'] ?? "https://via.placeholder.com/150",
              width: 130,
              height: 180,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 5,
              left: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  anime['anime_name'],
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
