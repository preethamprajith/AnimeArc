import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryPurple = Color(0xFF4A1A70);
const Color kDarkPurple = Color(0xFF2D1F4C);
const Color kLightPurple = Color(0xFF9B6DFF);
const Color kDeepPurple = Color(0xFF1A0F2C);

class Animedetails extends StatefulWidget {
  final int animeId;
  const Animedetails({super.key, required this.animeId});

  @override
  State<Animedetails> createState() => _AnimedetailsState();
}

class _AnimedetailsState extends State<Animedetails> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? animeDetails;
  Map<int, List<Map<String, dynamic>>> seasonEpisodes = {};
  late TabController _tabController;
  bool isLoading = true;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? currentlyPlayingUrl;
  bool isInWatchlist = false;
  final supabase = Supabase.instance.client;

  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  List<Map<String, dynamic>> reviews = [];
  bool isReviewSubmitting = false;
  bool hasUserReviewed = false;

  @override
  void initState() {
    super.initState();
    fetchAnimeDetails();
    checkWatchlistStatus();
    fetchReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> fetchAnimeDetails() async {
    try {
      final animeResponse = await supabase
          .from('tbl_anime')
          .select('*, tbl_genre(genre_name)')
          .eq('anime_id', widget.animeId)
          .single();

      final animeFiles = await supabase
          .from('tbl_animefile')
          .select()
          .eq('anime_id', widget.animeId);

      if (!mounted) return;

      final Map<int, List<Map<String, dynamic>>> tempSeasonEpisodes = {};
      
      if (animeFiles != null) {
        for (var file in animeFiles) {
          final season = int.tryParse(file['animefile_season']?.toString() ?? '') ?? 1;
          if (!tempSeasonEpisodes.containsKey(season)) {
            tempSeasonEpisodes[season] = [];
          }
          tempSeasonEpisodes[season]!.add(file);
        }
      }

      setState(() {
        animeDetails = animeResponse;
        seasonEpisodes = tempSeasonEpisodes;
        if (tempSeasonEpisodes.isNotEmpty) {
          _tabController = TabController(
            length: tempSeasonEpisodes.length,
            vsync: this,
          );
        }
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching anime details: $e');
      print('Stack trace: $stackTrace');
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

  Future<void> initializeVideo(String videoUrl) async {
    if (currentlyPlayingUrl == videoUrl) return;

    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _videoPlayerController = VideoPlayerController.network(videoUrl);
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

    setState(() {
      currentlyPlayingUrl = videoUrl;
    });
  }

  Future<void> checkWatchlistStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_watchlist')
          .select()
          .eq('anime_id', widget.animeId)
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        isInWatchlist = response != null;
      });
    } catch (e) {
      print('Error checking watchlist status: $e');
    }
  }

  Future<void> toggleWatchlist() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add to watchlist')),
        );
        return;
      }

      if (isInWatchlist) {
        // Remove from watchlist
        await supabase
            .from('tbl_watchlist')
            .delete()
            .eq('anime_id', widget.animeId)
            .eq('user_id', user.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from watchlist')),
        );
      } else {
        // Add to watchlist
        await supabase.from('tbl_watchlist').insert({
          'anime_id': widget.animeId,
          'user_id': user.id,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to watchlist')),
        );
      }

      setState(() {
        isInWatchlist = !isInWatchlist;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchReviews() async {
    try {
      final response = await supabase
          .from('tbl_review')
          .select('*, profiles:user_id(*)')
          .eq('anime_id', widget.animeId)
          .order('review_date', ascending: false);

      final user = supabase.auth.currentUser;
      
      // Check if user has already reviewed
      if (user != null) {
        final hasReviewed = await supabase
            .from('tbl_review')
            .select()
            .eq('anime_id', widget.animeId)
            .eq('user_id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            reviews = List<Map<String, dynamic>>.from(response);
            hasUserReviewed = hasReviewed != null;
            
            // If user has reviewed, pre-fill the review form
            if (hasReviewed != null) {
              _rating = double.tryParse(hasReviewed['review_rating'].toString()) ?? 0;
              _reviewController.text = hasReviewed['review_content'] ?? '';
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> submitReview() async {
    if (_reviewController.text.trim().isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add both rating and review')),
      );
      return;
    }

    setState(() => isReviewSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Must be logged in to review');
      }

      // Check if user has already reviewed
      final existingReview = await supabase
          .from('tbl_review')
          .select()
          .eq('anime_id', widget.animeId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingReview != null) {
        throw Exception('You have already reviewed this anime');
      }

      // Insert new review
      await supabase.from('tbl_review').insert({
        'review_rating': _rating.toString(),
        'review_content': _reviewController.text.trim(),
        'review_date': DateTime.now().toIso8601String(),
        'user_id': user.id,
        'anime_id': widget.animeId,
      });

      _reviewController.clear();
      setState(() => _rating = 0);
      await fetchReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isReviewSubmitting = false);
    }
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLightPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasUserReviewed) ...[
            Text(
              'Write a Review',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: kLightPurple,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              style: GoogleFonts.poppins(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: kDeepPurple,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kLightPurple.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kLightPurple.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isReviewSubmitting ? null : submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLightPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isReviewSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Review',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Reviews',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...reviews.map((review) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kDeepPurple,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kLightPurple.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < double.parse(review['review_rating']) 
                                  ? Icons.star 
                                  : Icons.star_border,
                              color: kLightPurple,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateTime.parse(review['review_date'])
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['review_content'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: kDeepPurple,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kLightPurple),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading anime...',
                style: GoogleFonts.poppins(
                  color: kLightPurple,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kDeepPurple,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: kPrimaryPurple,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.transparent,
                        ],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.network(
                      animeDetails!['anime_poster'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kDeepPurple.withOpacity(0.3),
                          kDeepPurple,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kDarkPurple.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInWatchlist ? kLightPurple : Colors.white24,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    color: isInWatchlist ? kLightPurple : Colors.white,
                  ),
                  onPressed: toggleWatchlist,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                decoration: BoxDecoration(
                  color: kDeepPurple,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animeDetails!['anime_name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kLightPurple, kPrimaryPurple],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          animeDetails!['tbl_genre']['genre_name'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kDarkPurple,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kLightPurple.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          animeDetails!['anime_description'] ?? 'No description available',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_chewieController != null)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kLightPurple.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Chewie(controller: _chewieController!),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildReviewSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (seasonEpisodes.isNotEmpty) ...[
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: seasonEpisodes.keys
                      .map((season) => Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: kLightPurple.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Season $season'),
                            ),
                          ))
                      .toList(),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorColor: kLightPurple,
                  labelColor: kLightPurple,
                  unselectedLabelColor: Colors.grey,
                ),
              ),
              pinned: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final currentSeason = seasonEpisodes.keys.elementAt(_tabController.index);
                    final episodes = seasonEpisodes[currentSeason] ?? [];
                    
                    if (index >= episodes.length) {
                      return null;
                    }

                    final episode = episodes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDarkPurple, kDeepPurple],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kLightPurple.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kLightPurple, kPrimaryPurple],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              episode['animefile_episode']?.toString() ?? '?',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          'Episode ${episode['animefile_episode'] ?? "Unknown"}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.play_circle_outline,
                          color: kLightPurple,
                          size: 32,
                        ),
                        onTap: () {
                          if (episode['animefile_file'] != null) {
                            initializeVideo(episode['animefile_file']);
                          }
                        },
                      ),
                    );
                  },
                  childCount: seasonEpisodes[seasonEpisodes.keys.elementAt(_tabController.index)]?.length ?? 0,
                ),
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No episodes available',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kDeepPurple,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
