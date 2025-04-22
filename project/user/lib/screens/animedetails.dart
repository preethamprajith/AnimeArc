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

  @override
  void initState() {
    super.initState();
    fetchAnimeDetails();
    checkWatchlistStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> fetchAnimeDetails() async {
    try {
      // Fetch anime details
      final animeResponse = await Supabase.instance.client
          .from('tbl_anime')
          .select('*, tbl_genre(genre_name)')
          .eq('anime_id', widget.animeId)
          .single();

      // Fetch anime files
      final animeFiles = await Supabase.instance.client
          .from('tbl_animefile')
          .select()
          .eq('anime_id', widget.animeId);

      // Organize episodes by season
      final Map<int, List<Map<String, dynamic>>> tempSeasonEpisodes = {};
      for (var file in animeFiles) {
        final season = int.parse(file['animefile_season']);
        if (!tempSeasonEpisodes.containsKey(season)) {
          tempSeasonEpisodes[season] = [];
        }
        tempSeasonEpisodes[season]!.add(file);
      }

      setState(() {
        animeDetails = animeResponse;
        seasonEpisodes = tempSeasonEpisodes;
        _tabController = TabController(
          length: seasonEpisodes.length,
          vsync: this,
        );
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching anime details: $e');
      setState(() => isLoading = false);
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
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                  final episodes = seasonEpisodes[seasonEpisodes.keys.elementAt(_tabController.index)]!;
                  final episode = episodes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
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
                            episode['animefile_episode'].toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'Episode ${episode['animefile_episode']}',
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
                      onTap: () => initializeVideo(episode['animefile_file']),
                    ),
                  );
                },
                childCount: seasonEpisodes[seasonEpisodes.keys.elementAt(_tabController.index)]?.length ?? 0,
              ),
            ),
          ),
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
