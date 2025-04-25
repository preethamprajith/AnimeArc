import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/animedetails.dart';
import 'package:user/screens/mangadetails.dart';
import 'package:user/screens/search_screen.dart';
import 'package:user/main.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorHandler {
  static void logError(String method, dynamic error, StackTrace? stackTrace) {
    print('Error in $method: $error');
    if (stackTrace != null) print('Stack trace: $stackTrace');
  }
}

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
    try {
      super.initState();
      _tabController = TabController(length: 2, vsync: this);
      _initializeData();
    } catch (e, stackTrace) {
      ErrorHandler.logError('initState', e, stackTrace);
    }
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        fetchGenresWithAnime(),
        fetchGenresWithManga(),
      ]);
    } catch (e, stackTrace) {
      ErrorHandler.logError('_initializeData', e, stackTrace);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchGenresWithAnime() async {
    try {
      final genreResponse = await Supabase.instance.client
          .from('tbl_genre')
          .select('*')
          .catchError((e, stackTrace) {
        throw Exception('Failed to fetch genres: $e');
      });

      final animeResponse = await Supabase.instance.client
          .from('tbl_anime')
          .select('*, tbl_genre(genre_name)')
          .catchError((e, stackTrace) {
        throw Exception('Failed to fetch anime: $e');
      });

      if (!mounted) return;

      setState(() {
        try {
          genres = List<Map<String, dynamic>>.from(genreResponse);
          animeByGenre = {};

          // Filter out invalid entries
          for (var anime in animeResponse) {
            if (anime['anime_id'] != null) {  // Only add if ID exists
              String genreName = anime['tbl_genre']['genre_name'] ?? "Unknown";
              if (!animeByGenre.containsKey(genreName)) {
                animeByGenre[genreName] = [];
              }
              animeByGenre[genreName]!.add(anime);
            }
          }
        } catch (e, stackTrace) {
          ErrorHandler.logError('setState in fetchGenresWithAnime', e, stackTrace);
          throw Exception('Failed to process anime data: $e');
        } finally {
          isLoading = false;
        }
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('fetchGenresWithAnime', e, stackTrace);
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading anime: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchGenresWithManga() async {
    try {
      final genreResponse = await Supabase.instance.client
          .from('tbl_genre')
          .select('*')
          .catchError((e, stackTrace) {
        throw Exception('Failed to fetch genres: $e');
      });

      final mangaResponse = await Supabase.instance.client
          .from('tbl_manga')
          .select('*, tbl_genre(genre_name)')
          .catchError((e, stackTrace) {
        throw Exception('Failed to fetch manga: $e');
      });

      if (!mounted) return;

      setState(() {
        try {
          genres = List<Map<String, dynamic>>.from(genreResponse);
          mangaByGenre = {};

          for (var manga in mangaResponse) {
            String genreName = manga['tbl_genre']['genre_name'] ?? "Unknown";
            if (!mangaByGenre.containsKey(genreName)) {
              mangaByGenre[genreName] = [];
            }
            mangaByGenre[genreName]!.add(manga);
          }
        } catch (e, stackTrace) {
          ErrorHandler.logError('setState in fetchGenresWithManga', e, stackTrace);
          throw Exception('Failed to process manga data: $e');
        }
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError('fetchGenresWithManga', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading manga: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: _buildAppTitle(),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AnimeTheme.accentPink),
              onPressed: () {}
            ),
            IconButton(
              icon: const Icon(Icons.search, color: AnimeTheme.accentPink),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ),
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
    } catch (e, stackTrace) {
      ErrorHandler.logError('build', e, stackTrace);
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Something went wrong',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildAppTitle() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "anime",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          TextSpan(
            text: "Hub",
            style: GoogleFonts.montserrat(
              color: AnimeTheme.accentPink,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeContent() {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: AnimeTheme.accentPink))
        : Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 130, left: 12, right: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: animeByGenre.entries.map((entry) {
                  return _buildGenreSection(entry.key, entry.value, isAnime: true);
                }).toList(),
              ),
            ),
          );
  }

  Widget _buildMangaContent() {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: AnimeTheme.accentPink))
        : Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 130, left: 12, right: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: mangaByGenre.entries.map((entry) {
                  return _buildGenreSection(entry.key, entry.value, isAnime: false);
                }).toList(),
              ),
            ),
          );
  }

  Widget _buildGenreSection(String genreName, List<Map<String, dynamic>> contentList, {required bool isAnime}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          genreName,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
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
    // Validate required data exists
    if (anime['anime_id'] == null || anime['anime_name'] == null) {
      ErrorHandler.logError(
        '_buildAnimeCard',
        'Invalid anime data: ${anime.toString()}',
        StackTrace.current
      );
      return const SizedBox.shrink();
    }
  
    return GestureDetector(
      onTap: () async {
        try {
          // Validate data before navigation
          final response = await supabase
              .from('tbl_anime')
              .select()
              .eq('anime_id', anime['anime_id'])
              .single();
              
          if (response != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Animedetails(
                  animeId: anime['anime_id'],
                ),
              ),
            );
          } else {
            throw Exception('Anime not found');
          }
        } catch (e, stackTrace) {
          ErrorHandler.logError('_buildAnimeCard navigation', e, stackTrace);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not load anime details: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  anime['anime_poster'] ?? "https://via.placeholder.com/150",
                  width: 150,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    ErrorHandler.logError('Image loading', error, stackTrace);
                    return Container(
                      width: 150,
                      height: 180,
                      color: Colors.grey[850],
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white54,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  anime['anime_name'] ?? "Unknown",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
