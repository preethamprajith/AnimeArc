import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/components/anime_card.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: AnimeTheme.accentPink),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AnimeTheme.accentPink),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AnimeTheme.accentPink,
          labelColor: AnimeTheme.accentPink,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 14,
            letterSpacing: 1,
          ),
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
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AnimeTheme.primaryPurple,
                  AnimeTheme.darkPurple,
                ],
              ),
            ),
          ),
          
          // Content
          TabBarView(
            controller: _tabController,
            children: [
              buildAnimeGrid(),
              buildGenreSelection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAnimeGrid() {
    return animeList.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AnimeTheme.accentPink),
                const SizedBox(height: 16),
                Text(
                  'Loading Anime...',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(top: 130),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
            ),
          );
  }

  Widget buildGenreSelection() {
    return Padding(
      padding: const EdgeInsets.only(top: 130),
      child: genreList.isEmpty 
          ? Center(child: CircularProgressIndicator(color: AnimeTheme.accentPink))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: genreList.length,
              itemBuilder: (context, index) {
                final genre = genreList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AnimeTheme.brightPurple.withOpacity(0.3),
                        AnimeTheme.primaryPurple.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AnimeTheme.accentPink.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    title: Text(
                      genre['genre_name'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: AnimeTheme.accentPink.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_forward, color: AnimeTheme.accentPink, size: 18),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedGenre = genre['genre_id'].toString();
                      });
                      fetchAnime(genreId: selectedGenre);
                      _tabController.animateTo(0);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget buildAnimeCard(String title, String? imageUrl, String genre) {
    return GestureDetector(
      onTap: () {
        // Navigate to anime details
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 4,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AnimeTheme.darkPurple,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : Container(
                        color: AnimeTheme.darkPurple,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: Colors.white70,
                        ),
                      ),
              ),
              
              // Info section
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AnimeTheme.primaryPurple.withOpacity(0.9),
                        AnimeTheme.darkPurple.withOpacity(0.9),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Genre
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AnimeTheme.accentPink.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          genre,
                          style: GoogleFonts.poppins(
                            color: AnimeTheme.accentPink,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
