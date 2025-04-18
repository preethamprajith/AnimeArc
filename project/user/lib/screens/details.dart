import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user/models/anime.dart';
import 'package:user/models/episode.dart';

class DetailsScreen extends StatefulWidget {
  final String animeId;
  
  const DetailsScreen({
    Key? key,
    required this.animeId,
  }) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Future<AnimeModel?> _animeFuture;
  List<EpisodeModel> _episodes = [];
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _animeFuture = _fetchAnimeDetails();
    _fetchEpisodes();
  }

  Future<AnimeModel?> _fetchAnimeDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_anime')
          .select('*')
          .eq('anime_id', widget.animeId)
          .single();
      
      return AnimeModel.fromMap(response);
    } catch (e) {
      print('Error fetching anime details: $e');
      return null;
    }
  }

  Future<void> _fetchEpisodes() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_episode')
          .select('*')
          .eq('anime_id', widget.animeId)
          .order('episode_number');
      
      setState(() {
        _episodes = List<Map<String, dynamic>>.from(response)
            .map((e) => EpisodeModel.fromMap(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching episodes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite 
                    ? 'Added to favorites!' 
                    : 'Removed from favorites!'),
                  backgroundColor: AnimeTheme.accentPink,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AnimeTheme.accentPink : Colors.white,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<AnimeModel?>(
        future: _animeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return _buildErrorState();
          }
          
          final anime = snapshot.data!;
          return _buildAnimeDetails(anime);
        },
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
              'Loading anime details...',
              style: AnimeTheme.bodyStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AnimeTheme.primaryGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 70,
              color: AnimeTheme.accentPink,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load anime details',
              style: AnimeTheme.subheadingStyle,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _animeFuture = _fetchAnimeDetails();
                  _fetchEpisodes();
                });
              },
              style: AnimeTheme.primaryButtonStyle,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimeDetails(AnimeModel anime) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AnimeTheme.primaryGradient,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Section
            _buildBannerSection(anime),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Anime Title and Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anime.animeName,
                              style: AnimeTheme.headingStyle,
                            ),
                            const SizedBox(height: 8),
                            // Tags row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildTag('Action'),
                                _buildTag('Fantasy'),
                                _buildTag('${2013 + (int.parse(anime.animeId) % 10)}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rating circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.2),
                          border: Border.all(
                            color: AnimeTheme.accentPink,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AnimeTheme.accentPink.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${8.5 + (int.parse(anime.animeId) % 15) / 10}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.star, color: AnimeTheme.accentPink, size: 12),
                                Icon(Icons.star, color: AnimeTheme.accentPink, size: 12),
                                Icon(Icons.star, color: AnimeTheme.accentPink, size: 12),
                                Icon(Icons.star, color: AnimeTheme.accentPink, size: 12),
                                Icon(Icons.star_half, color: AnimeTheme.accentPink, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Description with see more functionality
                  if (anime.animeDescription != null) ...[
                    Text(
                      'Story Overview',
                      style: AnimeTheme.subheadingStyle.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      anime.animeDescription!,
                      style: AnimeTheme.bodyStyle.copyWith(
                        height: 1.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        'Read more',
                        style: GoogleFonts.poppins(
                          color: AnimeTheme.accentPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  
                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AnimeTheme.accentPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            'Watch Now',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.download_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Episodes Section
                  _buildEpisodesSection(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AnimeTheme.brightPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBannerSection(AnimeModel anime) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Banner image
          Hero(
            tag: 'anime_banner_${anime.animeId}',
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: anime.animeBanner != null
                  ? Image.network(
                      anime.animeBanner!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AnimeTheme.brightPurple,
                              AnimeTheme.accentPink,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 50,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AnimeTheme.brightPurple,
                            AnimeTheme.accentPink,
                          ],
                        ),
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AnimeTheme.primaryPurple.withOpacity(0.8),
                    AnimeTheme.primaryPurple,
                  ],
                  stops: const [0.4, 0.85, 1.0],
                ),
              ),
            ),
          ),
          
          // Trending badge
          Positioned(
            top: 90,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AnimeTheme.accentPink,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: AnimeTheme.accentPink,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'TRENDING #${1 + (int.parse(anime.animeId) % 10)}',
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
          
          // Play button overlay
          Center(
            child: GestureDetector(
              onTap: () {
                // Play action
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with tab indicator
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AnimeTheme.accentPink, AnimeTheme.brightPurple],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AnimeTheme.accentPink.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Episodes',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Related',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Episodes count with filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_episodes.length} episodes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Episodes list
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: AnimeTheme.accentPink))
            : _episodes.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Icon(
                          Icons.video_library_outlined,
                          size: 60,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No episodes available yet',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back soon for updates',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _episodes.length,
                    itemBuilder: (context, index) {
                      final episode = _episodes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                        child: InkWell(
                          onTap: () {
                            // Play episode
                          },
                          borderRadius: BorderRadius.circular(16),
                          splashColor: AnimeTheme.accentPink.withOpacity(0.1),
                          highlightColor: AnimeTheme.accentPink.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Thumbnail with play overlay
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 120,
                                        height: 70,
                                        child: episode.episodeThumbnail != null
                                            ? Image.network(
                                                episode.episodeThumbnail!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: AnimeTheme.darkPurple,
                                                  child: const Icon(
                                                    Icons.movie,
                                                    color: Colors.white54,
                                                    size: 30,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: AnimeTheme.darkPurple,
                                                child: const Icon(
                                                  Icons.movie,
                                                  color: Colors.white54,
                                                  size: 30,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                    // Episode number badge
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          episode.episodeNumber,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                
                                // Episode info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Episode ${episode.episodeNumber}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        episode.episodeTitle,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Colors.white54,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            episode.duration ?? '24 min',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Download button
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    color: AnimeTheme.accentPink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ],
    );
  }
} 