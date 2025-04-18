import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(
          color: Colors.orange,
        )),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                animeDetails!['anime_poster'],
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                  color: isInWatchlist ? Colors.orange : Colors.white,
                ),
                onPressed: toggleWatchlist,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animeDetails!['anime_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    animeDetails!['anime_description'] ?? 'No description available',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Genre: ${animeDetails!['tbl_genre']['genre_name']}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 24),
                  if (_chewieController != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Chewie(controller: _chewieController!),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: seasonEpisodes.keys
                    .map((season) => Tab(text: 'Season $season'))
                    .toList(),
                indicatorColor: Colors.orange,
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.grey,
              ),
            ),
            pinned: true,
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: seasonEpisodes.entries.map((entry) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final episode = entry.value[index];
                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        title: Text(
                          'Episode ${episode['animefile_episode']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.play_circle_outline,
                            color: Colors.orange),
                        onTap: () {
                          initializeVideo(episode['animefile_file']);
                        },
                      ),
                    );
                  },
                );
              }).toList(),
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
      color: Colors.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
