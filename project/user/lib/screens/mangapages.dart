import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MangaPages extends StatefulWidget {
  final int mangafileId;
  final int chapterNumber;

  const MangaPages({
    super.key,
    required this.mangafileId,
    required this.chapterNumber,
  });

  @override
  State<MangaPages> createState() => _MangaPagesState();
}

class _MangaPagesState extends State<MangaPages> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pages = [];
  bool isLoading = true;
  late PageController _pageController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchPages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchPages() async {
    try {
      final response = await supabase
          .from('tbl_mangapage')
          .select()
          .eq('mangafile_id', widget.mangafileId)
          .order('mangapage_no');

      setState(() {
        pages = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching manga pages: $e');
      setState(() => isLoading = false);
    }
  }

  void toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Loading chapter...',
                style: TextStyle(color: Colors.orange[300]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: toggleControls,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Image.network(
                    pages[index]['mangapage_file'],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading page ${index + 1}...',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            if (_showControls) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'Chapter ${widget.chapterNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '${_pageController.hasClients ? (_pageController.page?.toInt() ?? 0) + 1 : 1}/${pages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
