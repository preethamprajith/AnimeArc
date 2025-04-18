import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/animedetails.dart';
import 'package:user/screens/mangadetails.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<Map<String, dynamic>> animeResults = [];
  List<Map<String, dynamic>> mangaResults = [];
  bool isLoading = false;
  String lastSearchTerm = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchDebounced);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onSearchDebounced() async {
    final searchTerm = _searchController.text.trim();
    
    if (searchTerm == lastSearchTerm) return;
    if (searchTerm.length < 2) {
      setState(() {
        animeResults = [];
        mangaResults = [];
      });
      return;
    }

    lastSearchTerm = searchTerm;
    _performSearch(searchTerm);
  }

  Future<void> _performSearch(String searchTerm) async {
    setState(() => isLoading = true);

    try {
      // Search anime
      final animeResponse = await Supabase.instance.client
          .from('tbl_anime')
          .select('*, tbl_genre(genre_name)')
          .ilike('anime_name', '%$searchTerm%')
          .limit(20);

      // Search manga
      final mangaResponse = await Supabase.instance.client
          .from('tbl_manga')
          .select('*, tbl_genre(genre_name)')
          .ilike('manga_title', '%$searchTerm%')
          .limit(20);

      if (mounted) {
        setState(() {
          animeResults = List<Map<String, dynamic>>.from(animeResponse);
          mangaResults = List<Map<String, dynamic>>.from(mangaResponse);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search anime or manga...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      animeResults = [];
                      mangaResults = [];
                    });
                  },
                )
              : null,
          ),
          autofocus: true,
        ),
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
          _buildAnimeResults(),
          _buildMangaResults(),
        ],
      ),
    );
  }

  Widget _buildAnimeResults() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Start typing to search anime...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (animeResults.isEmpty) {
      return const Center(
        child: Text(
          'No anime found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: animeResults.length,
      itemBuilder: (context, index) {
        final anime = animeResults[index];
        return _buildAnimeCard(anime);
      },
    );
  }

  Widget _buildMangaResults() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Start typing to search manga...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (mangaResults.isEmpty) {
      return const Center(
        child: Text(
          'No manga found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: mangaResults.length,
      itemBuilder: (context, index) {
        final manga = mangaResults[index];
        return _buildMangaCard(manga);
      },
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            anime['anime_poster'] ?? 'https://via.placeholder.com/50',
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(
                  width: 50,
                  height: 75,
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image, color: Colors.white54),
                ),
          ),
        ),
        title: Text(
          anime['anime_name'] ?? 'Unknown',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          anime['tbl_genre']['genre_name'] ?? 'Unknown genre',
          style: TextStyle(color: Colors.grey[400]),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Animedetails(animeId: anime['anime_id']),
          ),
        ),
      ),
    );
  }

  Widget _buildMangaCard(Map<String, dynamic> manga) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            manga['manga_cover'] ?? 'https://via.placeholder.com/50',
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(
                  width: 50,
                  height: 75,
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image, color: Colors.white54),
                ),
          ),
        ),
        title: Text(
          manga['manga_title'] ?? 'Unknown',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          manga['tbl_genre']['genre_name'] ?? 'Unknown genre',
          style: TextStyle(color: Colors.grey[400]),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetails(mangaId: manga['manga_id']),
          ),
        ),
      ),
    );
  }
}