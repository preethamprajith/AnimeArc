import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/animedetails.dart';
import 'package:user/screens/mangadetails.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:user/screens/search_screen.dart';

const Color kPrimaryPurple = Color(0xFF4A1A70);
const Color kDarkPurple = Color(0xFF2D1F4C);
const Color kLightPurple = Color(0xFF9B6DFF);
const Color kDeepPurple = Color(0xFF1A0F2C);

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
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        fetchAnimeWatchlist(),
        fetchMangaWatchlist(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  Future<void> _refreshData() async {
    if (isRefreshing) return;
    
    setState(() => isRefreshing = true);
    
    try {
      await Future.wait([
        fetchAnimeWatchlist(),
        fetchMangaWatchlist(),
      ]);
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  Future<void> fetchAnimeWatchlist() async {
    if (!mounted) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await supabase
          .from('tbl_watchlist')
          .select('*, tbl_anime!inner(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          animeWatchlist = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching anime watchlist: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchMangaWatchlist() async {
    if (!mounted) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await supabase
          .from('tbl_watchlist')
          .select('*, tbl_manga!inner(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          mangaWatchlist = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching manga watchlist: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget buildEmptyState(String type) {
    final bool isAnime = type.toLowerCase() == 'anime';
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kLightPurple.withOpacity(0.1),
            ),
            child: Icon(
              isAnime ? Icons.tv_rounded : Icons.book_rounded,
              size: 80,
              color: kLightPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your $type Collection is Empty",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Start adding your favorite $type to your collection!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              ).then((_) {
                // Refresh the watchlist when returning from search
                _refreshData();
              });
            },
            icon: Icon(
              isAnime ? Icons.tv_rounded : Icons.book_rounded,
              size: 24,
            ),
            label: Text(
              "Browse $type",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kLightPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistItem(Map<String, dynamic> item, bool isAnime) {
    final title = isAnime ? item['tbl_anime']['anime_name'] : item['tbl_manga']['manga_title'];
    final image = isAnime ? item['tbl_anime']['anime_poster'] : item['tbl_manga']['manga_cover'];
    final id = isAnime ? item['tbl_anime']['anime_id'] : item['tbl_manga']['manga_id'];

    return Hero(
      tag: '${isAnime ? 'anime' : 'manga'}_$id',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isAnime
                      ? Animedetails(animeId: id)
                      : MangaDetails(mangaId: id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Image
                    Positioned.fill(
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    // Title overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepPurple,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: kLightPurple,
        backgroundColor: kDarkPurple,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 150,
              floating: false,
              pinned: true,
              backgroundColor: kPrimaryPurple,
              elevation: 0,
              title: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [kLightPurple, Colors.white],
                ).createShader(bounds),
                child: Text(
                  'My Collection',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        kPrimaryPurple,
                        kDarkPurple.withOpacity(0.9),
                        kDeepPurple,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kLightPurple.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ).createShader(bounds),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topRight,
                                radius: 1.5,
                                colors: [
                                  kLightPurple.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  decoration: BoxDecoration(
                    color: kDeepPurple.withOpacity(0.5),
                    border: Border(
                      bottom: BorderSide(
                        color: kLightPurple.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 3,
                    indicatorColor: kLightPurple,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: [
                      _buildEnhancedTab('ANIME', animeWatchlist.length, Icons.tv_rounded),
                      _buildEnhancedTab('MANGA', mangaWatchlist.length, Icons.book_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildWatchlistView(true),
              _buildWatchlistView(false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTab(String text, int count, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: kLightPurple.withOpacity(0.2),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kDarkPurple.withOpacity(0.5),
              kDeepPurple.withOpacity(0.5),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kLightPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: kLightPurple.withOpacity(0.3),
                ),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kLightPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int count, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text('$text ($count)'),
        ],
      ),
    );
  }

  Widget _buildWatchlistView(bool isAnime) {
    final items = isAnime ? animeWatchlist : mangaWatchlist;
    final type = isAnime ? 'Anime' : 'Manga';

    if (isLoading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: kLightPurple,
          size: 50,
        ),
      );
    }

    if (items.isEmpty) {
      return buildEmptyState(type);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          // Implement pagination here if needed
        }
        return true;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildWatchlistItem(items[index], isAnime),
      ),
    );
  }
}
