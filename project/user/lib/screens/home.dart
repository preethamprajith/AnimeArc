import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/models/anime.dart';
import 'package:user/models/category.dart';
import 'package:user/screens/details.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<AnimeModel> _animeList = [];
  List<CategoryModel> _categoriesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _fetchTrendingAnime(),
        _fetchCategories(),
      ]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTrendingAnime() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_anime')
          .select('anime_id, anime_name, anime_poster, anime_banner, anime_description')
          .limit(10);

      if (mounted) {
        setState(() {
          _animeList = List<Map<String, dynamic>>.from(response)
              .map((e) => AnimeModel.fromMap(e))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching anime: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_category')
          .select('category_id, category_name, category_icon');

      if (mounted) {
        setState(() {
          _categoriesList = List<Map<String, dynamic>>.from(response)
              .map((e) => CategoryModel.fromMap(e))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AnimeTheme.accentPink.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: AnimeTheme.accentPink,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AnimeArc',
              style: AnimeTheme.headingStyle.copyWith(
                fontSize: 24,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AnimeTheme.accentPink),
              onPressed: () {},
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: AnimeTheme.accentPink),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Container(
              decoration: const BoxDecoration(
                gradient: AnimeTheme.primaryGradient,
              ),
              child: SafeArea(
                child: RefreshIndicator(
                  color: AnimeTheme.accentPink,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildFeaturedAnime(),
                          const SizedBox(height: 30),
                          _buildCategorySection(),
                          const SizedBox(height: 30),
                          _buildTrendingAnimeSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AnimeTheme.primaryGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AnimeTheme.accentPink),
            const SizedBox(height: 20),
            Text(
              'Loading awesome anime content...',
              style: AnimeTheme.bodyStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedAnime() {
    if (_animeList.isEmpty) return const SizedBox.shrink();
    
    final featuredAnime = _animeList.first;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(animeId: featuredAnime.animeId),
          ),
        );
      },
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Banner image
            Hero(
              tag: 'anime_banner_${featuredAnime.animeId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: featuredAnime.animeBanner != null
                    ? Image.network(
                        featuredAnime.animeBanner!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AnimeTheme.brightPurple,
                                AnimeTheme.accentPink,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 50,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AnimeTheme.brightPurple,
                              AnimeTheme.accentPink,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.movie_outlined,
                          size: 50,
                          color: Colors.white70,
                        ),
                      ),
              ),
            ),
            
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            
            // Featured tag with spotlight effect
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AnimeTheme.accentPink,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AnimeTheme.accentPink.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'FEATURED',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Title and description
            Positioned(
              bottom: 16,
              left: 16,
              right: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    featuredAnime.animeName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (featuredAnime.animeDescription != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      featuredAnime.animeDescription!,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Play button with glow effect
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: AnimeTheme.accentPink,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AnimeTheme.accentPink.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: AnimeTheme.subheadingStyle,
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  color: AnimeTheme.accentPink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: _categoriesList.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: AnimeTheme.accentPink,
                    strokeWidth: 3,
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categoriesList.length,
                  itemBuilder: (context, index) {
                    final category = _categoriesList[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AnimeTheme.brightPurple.withOpacity(0.6),
                            AnimeTheme.darkPurple.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AnimeTheme.accentPink.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AnimeTheme.accentPink.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getCategoryIcon(category.categoryIcon),
                              color: AnimeTheme.accentPink,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.categoryName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrendingAnimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Trending Now',
                  style: AnimeTheme.subheadingStyle,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AnimeTheme.accentPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'HOT',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  color: AnimeTheme.accentPink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: _animeList.isEmpty
              ? Center(child: CircularProgressIndicator(color: AnimeTheme.accentPink))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _animeList.length,
                  itemBuilder: (context, index) {
                    final anime = _animeList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(animeId: anime.animeId),
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 15),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poster image with rating
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                              child: Stack(
                                children: [
                                  // Poster image
                                  Hero(
                                    tag: 'anime_poster_${anime.animeId}',
                                    child: SizedBox(
                                      height: 200,
                                      width: 160,
                                      child: anime.animePoster != null
                                          ? Image.network(
                                              anime.animePoster!,
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
                                  ),
                                  
                                  // Rating badge
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AnimeTheme.accentPink,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: AnimeTheme.accentPink,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '9.${index + 1}',
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Title
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AnimeTheme.brightPurple.withOpacity(0.3),
                                      AnimeTheme.darkPurple.withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      anime.animeName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'movie':
        return Icons.movie_outlined;
      case 'tv':
        return Icons.tv_outlined;
      case 'action':
        return Icons.sports_martial_arts_outlined;
      case 'comedy':
        return Icons.sentiment_very_satisfied_outlined;
      case 'romance':
        return Icons.favorite_outline;
      case 'adventure':
        return Icons.explore_outlined;
      case 'fantasy':
        return Icons.auto_awesome_outlined;
      case 'scifi':
        return Icons.rocket_outlined;
      case 'horror':
        return Icons.warning_outlined;
      default:
        return Icons.category_outlined;
    }
  }
} 