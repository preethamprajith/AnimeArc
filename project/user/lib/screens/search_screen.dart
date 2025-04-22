import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/animedetails.dart';
import 'package:user/screens/mangadetails.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryPurple = Color(0xFF4A1A70);
const Color kDarkPurple = Color(0xFF2D1F4C);
const Color kLightPurple = Color(0xFF9B6DFF);
const Color kDeepPurple = Color(0xFF1A0F2C);

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
      backgroundColor: kDeepPurple,
      appBar: AppBar(
        backgroundColor: kPrimaryPurple,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: kDarkPurple.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: kLightPurple.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Search anime or manga...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: kLightPurple,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kLightPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: kLightPurple,
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            animeResults = [];
                            mangaResults = [];
                          });
                        },
                      ),
                    )
                  : null,
            ),
            autofocus: true,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: kDarkPurple,
              border: Border(
                bottom: BorderSide(
                  color: kLightPurple.withOpacity(0.2),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: kLightPurple,
              indicatorWeight: 3,
              labelColor: kLightPurple,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "ANIME"),
                Tab(text: "MANGA"),
              ],
            ),
          ),
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
      return _buildLoadingIndicator();
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Start typing to search anime...');
    }

    if (animeResults.isEmpty) {
      return _buildEmptyState('No anime found');
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
      return _buildLoadingIndicator();
    }

    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Start typing to search manga...');
    }

    if (mangaResults.isEmpty) {
      return _buildEmptyState('No manga found');
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

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kLightPurple),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: GoogleFonts.poppins(
              color: kLightPurple,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: kLightPurple.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kDarkPurple,
            kDeepPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kLightPurple.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Animedetails(animeId: anime['anime_id']),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'anime_${anime['anime_id']}',
                  child: Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        anime['anime_poster'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: kDarkPurple,
                          child: Icon(
                            Icons.broken_image,
                            color: kLightPurple.withOpacity(0.5),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime['anime_name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kLightPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: kLightPurple.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          anime['tbl_genre']['genre_name'],
                          style: GoogleFonts.poppins(
                            color: kLightPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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