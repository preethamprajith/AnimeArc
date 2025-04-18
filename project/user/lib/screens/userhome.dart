import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/animedetails.dart';
import 'package:user/screens/mangadetails.dart';
import 'package:user/screens/search_screen.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> genres = [];
  Map<String, List<Map<String, dynamic>>> animeByGenre = {};
  Map<String, List<Map<String, dynamic>>> mangaByGenre = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchGenresWithAnime();
    fetchGenresWithManga();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      print("Error fetching anime data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchGenresWithManga() async {
    try {
      final genreResponse = await Supabase.instance.client.from('tbl_genre').select('*');
      final mangaResponse = await Supabase.instance.client.from('tbl_manga').select('*, tbl_genre(genre_name)');

      setState(() {
        genres = List<Map<String, dynamic>>.from(genreResponse);
        mangaByGenre = {};

        for (var manga in mangaResponse) {
          String genreName = manga['tbl_genre']['genre_name'] ?? "Unknown";
          if (!mangaByGenre.containsKey(genreName)) {
            mangaByGenre[genreName] = [];
          }
          mangaByGenre[genreName]!.add(manga);
        }
      });
    } catch (e) {
      print("Error fetching manga data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Animearc', 
          style: TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.orange), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.orange),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "ANIME"),
            Tab(text: "MANGA"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnimeContent(),
          _buildMangaContent(),
        ],
      ),
    );
  }

  Widget _buildAnimeContent() {
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: animeByGenre.entries.map((entry) {
                return _buildGenreSection(entry.key, entry.value, isAnime: true);
              }).toList(),
            ),
          );
  }

  Widget _buildMangaContent() {
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mangaByGenre.entries.map((entry) {
                return _buildGenreSection(entry.key, entry.value, isAnime: false);
              }).toList(),
            ),
          );
  }

  Widget _buildGenreSection(String genreName, List<Map<String, dynamic>> contentList, {required bool isAnime}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(genreName, 
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: contentList.length,
            itemBuilder: (context, index) {
              return isAnime 
                ? _buildAnimeCard(contentList[index])
                : _buildMangaCard(contentList[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => Animedetails(animeId: anime['anime_id']))
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6)
                  ),
                  child: Text(
                    anime['anime_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMangaCard(Map<String, dynamic> manga) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MangaDetails(mangaId: manga['manga_id']),
  ),
);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                manga['manga_cover'] ?? "https://via.placeholder.com/150",
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
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6)
                  ),
                  child: Text(
                    manga['manga_title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
