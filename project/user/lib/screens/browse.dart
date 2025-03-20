import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Browse extends StatefulWidget {
  const Browse({super.key});

  @override
  State<Browse> createState() => _BrowseState();
}

class _BrowseState extends State<Browse> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> animeList = [];
  List<Map<String, dynamic>> genreList = [];
  String? selectedGenre;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAnime();
    fetchGenres();
  }

  Future<void> fetchAnime({String? genreId}) async {
    try {
      var query = Supabase.instance.client
          .from('tbl_anime')
          .select('anime_id, anime_name, anime_poster, genre_id, tbl_genre(genre_name)');

      if (genreId != null) {
        query = query.eq('genre_id', genreId);
      }

      final response = await query;
      if (mounted) {
        setState(() {
          animeList = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print("Error fetching anime: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Browse', style: TextStyle(color: Colors.white)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          onTap: (index) {
            if (index == 1) {
              fetchGenres();
            } else {
              fetchAnime();
            }
          },
          tabs: const [
            Tab(text: "ALL ANIME"),
            Tab(text: "ANIME GENRES"),
          ],
        ),
      ),
      backgroundColor: Colors.black87,
      body: TabBarView(
        controller: _tabController,
        children: [
          buildAnimeGrid(),
          buildGenreSelection(),
        ],
      ),
    );
  }

  Widget buildAnimeGrid() {
    return animeList.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return buildAnimeCard(
                anime['anime_name'],
                anime['anime_poster'],
                anime['tbl_genre']['genre_name'],
              );
            },
          );
  }

  Widget buildGenreSelection() {
    return ListView(
      children: genreList.map((genre) {
        return ListTile(
          title: Text(
            genre['genre_name'],
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(Icons.arrow_forward, color: Colors.white),
          onTap: () {
            setState(() {
              selectedGenre = genre['genre_id'].toString();
            });
            fetchAnime(genreId: selectedGenre);
            _tabController.animateTo(0);
          },
        );
      }).toList(),
    );
  }

  Widget buildAnimeCard(String title, String? imageUrl, String genre) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          imageUrl != null
              ? Image.network(imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover)
              : const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
                Text(genre, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
