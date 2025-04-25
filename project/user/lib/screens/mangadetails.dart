import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/mangapages.dart';
import 'package:google_fonts/google_fonts.dart';

class MangaDetails extends StatefulWidget {
  final int mangaId;
  const MangaDetails({super.key, required this.mangaId});

  @override
  State<MangaDetails> createState() => _MangaDetailsState();
}

class _MangaDetailsState extends State<MangaDetails> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? mangaDetails;
  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;
  bool isInWatchlist = false;

  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  List<Map<String, dynamic>> reviews = [];
  bool isReviewSubmitting = false;
  bool hasUserReviewed = false;

  @override
  void initState() {
    super.initState();
    fetchMangaDetails();
    checkWatchlistStatus();
    fetchReviews();
  }

  Future<void> fetchMangaDetails() async {
    try {
      final mangaResponse = await supabase
          .from('tbl_manga')
          .select('*, tbl_genre(genre_name)')
          .eq('manga_id', widget.mangaId)
          .single();

      final chaptersResponse = await supabase
          .from('tbl_mangafile')
          .select()
          .eq('manga_id', widget.mangaId)
          .order('chapter_number');

      setState(() {
        mangaDetails = mangaResponse;
        chapters = List<Map<String, dynamic>>.from(chaptersResponse);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching manga details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> checkWatchlistStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_watchlist')
          .select()
          .eq('manga_id', widget.mangaId)
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
        await supabase
            .from('tbl_watchlist')
            .delete()
            .eq('manga_id', widget.mangaId)
            .eq('user_id', user.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from watchlist'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        await supabase.from('tbl_watchlist').insert({
          'manga_id': widget.mangaId,
          'user_id': user.id,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to watchlist'),
            backgroundColor: Colors.green,
          ),
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
          .eq('manga_id', widget.mangaId)
          .order('review_date', ascending: false);

      final user = supabase.auth.currentUser;
      if (mounted) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(response);
          hasUserReviewed = user != null && 
              reviews.any((review) => review['user_id'] == user.id);
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  Future<void> submitReview() async {
    if (hasUserReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already reviewed this manga'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

      await supabase.from('tbl_review').insert({
        'review_rating': _rating.toString(),
        'review_content': _reviewController.text.trim(),
        'review_date': DateTime.now().toIso8601String(),
        'user_id': user.id,
        'manga_id': widget.mangaId,
      });

      _reviewController.clear();
      setState(() => _rating = 0);
      await fetchReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    } finally {
      setState(() => isReviewSubmitting = false);
    }
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1F4C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B6DFF).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
                    color: const Color(0xFF9B6DFF),
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
                fillColor: const Color(0xFF1A0F2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF9B6DFF).withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF9B6DFF).withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isReviewSubmitting ? null : submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B6DFF),
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
                color: const Color(0xFF1A0F2C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF9B6DFF).withOpacity(0.2),
                ),
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
                          color: const Color(0xFF9B6DFF),
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
        backgroundColor: const Color(0xFF1A0F2C),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B6DFF)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading manga details...',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9B6DFF),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A0F2C),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: const Color(0xFF2D1F4C),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'manga_${widget.mangaId}',
                    child: Image.network(
                      mangaDetails!['manga_cover'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1A0F2C).withOpacity(0.8),
                          const Color(0xFF1A0F2C),
                        ],
                        stops: const [0.3, 0.8, 1.0],
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
                  color: const Color(0xFF2D1F4C).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isInWatchlist ? const Color(0xFF9B6DFF) : Colors.white24,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B6DFF).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    color: isInWatchlist ? const Color(0xFF9B6DFF) : Colors.white,
                    size: 28,
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
                  color: const Color(0xFF1A0F2C),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B6DFF).withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mangaDetails!['manga_title'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9B6DFF), Color(0xFF6B4EE6)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF9B6DFF).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              mangaDetails!['tbl_genre']['genre_name'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'By ${mangaDetails!['manga_author']}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF9B6DFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D1F4C),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          mangaDetails!['manga_description'] ?? 'No description available',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Chapters',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D1F4C),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '${chapters.length} chapters',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF9B6DFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildReviewSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapter = chapters[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D1F4C),
                        const Color(0xFF1A0F2C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9B6DFF).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B6DFF), Color(0xFF6B4EE6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9B6DFF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${chapter['chapter_number']}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Chapter ${chapter['chapter_number']}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Released: ${DateTime.parse(chapter['release_date']).toString().split(' ')[0]}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF9B6DFF).withOpacity(0.2),
                            const Color(0xFF6B4EE6).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF9B6DFF),
                        size: 20,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MangaPages(
                            mangafileId: chapter['mangafile_id'],
                            chapterNumber: chapter['chapter_number'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              childCount: chapters.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}
