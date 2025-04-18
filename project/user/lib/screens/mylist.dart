import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/animedetails.dart';
import 'package:user/screens/mangadetails.dart';

class MyList extends StatefulWidget {
  const MyList({super.key});

  @override
  State<MyList> createState() => _MyListState();
}

class _MyListState extends State<MyList> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> animeWatchlist = [];
  List<Map<String, dynamic>> mangaWatchlist = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAnimeWatchlist();
    fetchMangaWatchlist();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchAnimeWatchlist() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_watchlist')
          .select('*, tbl_anime!inner(*)')
          .eq('user_id', user.id);

      setState(() {
        animeWatchlist = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching anime watchlist: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchMangaWatchlist() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_watchlist')
          .select('*, tbl_manga!inner(*)')
          .eq('user_id', user.id);

      setState(() {
        mangaWatchlist = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching manga watchlist: $e');
      setState(() => isLoading = false);
    }
  }

  Widget buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('./assets/tv_cat.png', width: 150),
          const SizedBox(height: 20),
          Text(
            "Your $type Watchlist needs some love.",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Let's fill it up with awesome $type.",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAnimeWatchlist() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (animeWatchlist.isEmpty) {
      return buildEmptyState('Anime');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: animeWatchlist.length,
      itemBuilder: (context, index) {
        final anime = animeWatchlist[index]['tbl_anime'];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Animedetails(animeId: anime['anime_id']),
              ),
            );
          },
          child: Card(
            color: Colors.grey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    anime['anime_poster'],
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    anime['anime_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildMangaWatchlist() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (mangaWatchlist.isEmpty) {
      return buildEmptyState('Manga');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: mangaWatchlist.length,
      itemBuilder: (context, index) {
        final manga = mangaWatchlist[index]['tbl_manga'];
        return GestureDetector(
          onTap: () {
            // Navigate to manga details page when implemented
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MangaDetails(mangaId: manga['manga_id']),
              ),
            );
          },
          child: Card(
            color: Colors.grey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    manga['manga_cover'],
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    manga['manga_title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('My Lists', style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
          tabs: const [
            Tab(text: "ANIME"),
            Tab(text: "MANGA"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildAnimeWatchlist(),
          buildMangaWatchlist(),
        ],
      ),
      backgroundColor: Colors.black87,
    );
  }
}
