import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> reviews = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchComplaints();
    fetchReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchComplaints() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await Supabase.instance.client
          .from('tbl_complaint')
          .select('''
            complaint_id,
            complaint_title,
            complaint_content,
            complaint_replay,
            complaint_status,
            complaint_date,
            complaint_screenshot,
            tbl_user (
              user_id,
              user_name
            )
          ''')
          .order('complaint_date', ascending: false);

      // Validate and transform screenshot URLs
      final validatedComplaints = List<Map<String, dynamic>>.from(response).map((complaint) {
        if (complaint['complaint_screenshot'] != null) {
          final screenshotUrl = complaint['complaint_screenshot'].toString();
          if (!screenshotUrl.startsWith('http')) {
            // Construct full Supabase URL if needed
            complaint['complaint_screenshot'] = Supabase.instance.client
                .storage
                .from('complaint')
                .getPublicUrl(screenshotUrl);
          }
        }
        return complaint;
      }).toList();

      if (mounted) {
        setState(() {
          complaints = validatedComplaints;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching complaints: $error');
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchReviews() async {
    try {
      setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('tbl_review')
          .select('''
            review_id,
            review_rating,
            review_content,
            review_date,
            tbl_user (
              user_id,
              user_name
            ),
            tbl_manga (
              manga_id,
              manga_title,
              manga_cover
            ),
            tbl_anime (
              anime_id,
              anime_name,
              anime_poster
            ),
            tbl_product (
              product_id,
              product_name,
              product_image
            )
          ''')
          .order('review_date', ascending: false);

      if (mounted) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching reviews: $error');
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateComplaintStatus(int complaintId, String reply) async {
    try {
      await Supabase.instance.client
          .from('tbl_complaint')
          .update({
            'complaint_replay': reply,  // Changed from 'complaint_reply' to 'complaint_replay'
            'complaint_status': 'Resolved'
          })
          .eq('complaint_id', complaintId);

      await fetchComplaints(); // Refresh the list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error updating complaint: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reply: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews & Complaints'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reviews'),
            Tab(text: 'Complaints'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              fetchReviews();
              fetchComplaints();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Reviews Tab
          _buildReviewsTab(),
          // Complaints Tab
          _buildComplaintsTab(),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return const Center(child: Text('No reviews found'));
    }

    return RefreshIndicator(
      onRefresh: fetchReviews,
      child: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          final rating = int.tryParse(review['review_rating']?.toString() ?? '0') ?? 0;

          // Determine review type and title
          String reviewType = '';
          String itemTitle = '';
          
          if (review['tbl_manga']?['manga_title'] != null) {
            reviewType = 'Manga';
            itemTitle = review['tbl_manga']['manga_title'];
          } else if (review['tbl_anime']?['anime_name'] != null) {  // Changed from anime_title to anime_name
            reviewType = 'Anime';
            itemTitle = review['tbl_anime']['anime_name'];  // Changed from anime_title to anime_name
          } else if (review['tbl_product']?['product_name'] != null) {
            reviewType = 'Product';
            itemTitle = review['tbl_product']['product_name'];
          }
          
          // Replace the existing Card widget in _buildReviewsTab
          return Card(
            margin: const EdgeInsets.all(8),
            child: SizedBox(
              height: 180, // Fixed height instead of IntrinsicHeight
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image section with fixed dimensions
                  AspectRatio(
                    aspectRatio: 2/3,
                    child: _buildItemImage(review),
                  ),
                  // Content section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type and Title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(reviewType),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  reviewType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  itemTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Rating stars
                          Row(
                            children: List.generate(
                              rating,
                              (index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // User and date info
                          Text(
                            'By: ${review['tbl_user']?['user_name'] ?? 'Unknown User'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Date: ${DateTime.parse(review['review_date']).toString().split('.')[0]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          // Review content
                          Expanded(
                            child: Text(
                              review['review_content'] ?? 'No content',
                              maxLines: 3,
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
          );
        },
      ),
    );
  }

  Widget _buildComplaintsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchComplaints,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_complaints.png', // Add this image to your assets
              height: 120,
            ),
            const SizedBox(height: 16),
            const Text(
              'No complaints yet!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.deepPurple.withOpacity(0.2),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: fetchComplaints,
        color: Colors.deepPurple,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            final isResolved = complaint['complaint_status'] == 'Resolved';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  title: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isResolved ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isResolved ? Icons.check_circle : Icons.pending_actions,
                          color: isResolved ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint['complaint_title'] ?? 'No Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'From: ${complaint['tbl_user']?['user_name'] ?? 'Unknown User'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isResolved ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isResolved ? Colors.green : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          complaint['complaint_status'] ?? 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: isResolved ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Submitted on ${complaint['complaint_date'] ?? 'Unknown Date'}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(complaint['complaint_content'] ?? 'No Content'),
                          ),
                          if (complaint['complaint_screenshot'] != null) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                complaint['complaint_screenshot'],
                                fit: BoxFit.cover,
                                height: 200,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return _buildImageLoadingIndicator(loadingProgress);
                                },
                                errorBuilder: _buildImageError,
                              ),
                            ),
                          ],
                          if (complaint['complaint_replay'] != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.deepPurple.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, 
                                        size: 20, 
                                        color: Colors.deepPurple
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Admin Response',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(complaint['complaint_replay'] ?? ''),
                                ],
                              ),
                            ),
                          ],
                          if (complaint['complaint_status'] != 'Resolved')
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: ElevatedButton.icon(
                                onPressed: () => _showReplyDialog(complaint),
                                icon: const Icon(Icons.reply),
                                label: const Text('Reply to Complaint'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24, 
                                    vertical: 12
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemImage(Map<String, dynamic> review) {
    String? imageUrl;
    if (review['tbl_manga']?['manga_cover'] != null) {
      imageUrl = review['tbl_manga']['manga_cover'];
    } else if (review['tbl_anime']?['anime_poster'] != null) {
      imageUrl = review['tbl_anime']['anime_poster'];
    } else if (review['tbl_product']?['product_image'] != null) {
      imageUrl = review['tbl_product']['product_image'];
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
        color: Colors.grey[200],
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return const Icon(Icons.image_not_supported, size: 40);
                },
              ),
            )
          : const Icon(Icons.image_not_supported, size: 40),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Manga':
        return Colors.blue;
      case 'Anime':
        return Colors.purple;
      case 'Product':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildImageLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Container(
      height: 200,
      color: Colors.grey[100],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / 
                loadingProgress.expectedTotalBytes!
              : null,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildImageError(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      height: 200,
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(Map<String, dynamic> complaint) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reply to Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: replyController,
              decoration: InputDecoration(
                labelText: 'Your Reply',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (replyController.text.isNotEmpty) {
                Navigator.pop(context);
                _updateComplaintStatus(
                  complaint['complaint_id'],
                  replyController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }
}