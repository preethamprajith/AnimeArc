import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class UploadAnimeVideo extends StatefulWidget {
  final int animeId;
  const UploadAnimeVideo({super.key, required this.animeId});

  @override
  State<UploadAnimeVideo> createState() => _UploadAnimeVideoState();
}

class _UploadAnimeVideoState extends State<UploadAnimeVideo>
    with TickerProviderStateMixin {
  final TextEditingController _episodeController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  List<Map<String, dynamic>> animeFiles = [];
  late TabController _tabController;
  List<int> seasons = [];

  PlatformFile? pickedVideo;
  String? selectedGenreId;
  List<Map<String, dynamic>> genreList = [];

  @override
  void initState() {
    super.initState();
    // Initialize TabController with default value
    _tabController = TabController(length: 1, vsync: this);
    fetchGenres();
    fetchAnimeFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchGenres() async {
    try {
      final response =
          await Supabase.instance.client.from('tbl_genre').select();
      setState(() {
        genreList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      showSnackbar("Error fetching genres", Colors.red);
    }
  }

  Future<void> fetchAnimeFiles() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_animefile')
          .select()
          .eq('anime_id', widget.animeId)
          .order('animefile_season, animefile_episode');

      setState(() {
        animeFiles = List<Map<String, dynamic>>.from(response);
        // Extract unique seasons
        seasons = animeFiles
            .map((file) => int.parse(file['animefile_season'].toString()))
            .toSet()
            .toList()
          ..sort();

        // Dispose old controller before creating new one
        _tabController.dispose();
        // Create new controller with updated length
        _tabController = TabController(
            length: seasons.isEmpty ? 1 : seasons.length, 
            vsync: this
        );
      });
    } catch (e) {
      print("Error fetching anime files: $e");
      showSnackbar("Error fetching anime files", Colors.red);
    }
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        pickedVideo = result.files.first;
      });
    }
  }

  Future<String?> uploadVideoToSupabase() async {
    if (pickedVideo == null) return null;

    try {
      final bucketName = 'anime';
      final now = DateTime.now();
      final timestamp = DateFormat('dd-MM-yy-HH-mm-ss').format(now);
      final fileExtension = pickedVideo!.name.split('.').last;
      final fileName = "$timestamp.$fileExtension";

      // Check file size (limit to 100MB for example)
      if (pickedVideo!.size > 100 * 1024 * 1024) {
        throw Exception('File size exceeds 100MB limit');
      }

      // Check file type
      if (!['mp4', 'mkv', 'avi', 'mov'].contains(fileExtension.toLowerCase())) {
        throw Exception('Unsupported file format. Use mp4, mkv, avi, or mov');
      }

      await Supabase.instance.client.storage.from(bucketName).uploadBinary(
        fileName,
        pickedVideo!.bytes!,
      );

      return Supabase.instance.client.storage.from(bucketName).getPublicUrl(fileName);
    } on StorageException catch (e) {
      print('Storage error: ${e.message}');
      showSnackbar("Storage error: ${e.message}", Colors.red);
      return null;
    } on Exception catch (e) {
      print('Upload error: $e');
      showSnackbar(e.toString(), Colors.red);
      return null;
    }
  }

  Future<void> insertAnimeVideo() async {
    try {
      // Validate inputs
      if (_episodeController.text.isEmpty || _seasonController.text.isEmpty) {
        throw Exception('Episode and season numbers are required');
      }

      if (int.tryParse(_episodeController.text) == null || 
          int.tryParse(_seasonController.text) == null) {
        throw Exception('Episode and season must be valid numbers');
      }

      if (pickedVideo == null) {
        throw Exception('Please select a video file');
      }

      // Upload video
      String? videoUrl = await uploadVideoToSupabase();
      if (videoUrl == null) {
        throw Exception('Failed to upload video');
      }

      // Check for duplicate episode
      final existingEpisodes = await Supabase.instance.client
          .from('tbl_animefile')
          .select()
          .eq('anime_id', widget.animeId)
          .eq('animefile_season', _seasonController.text)
          .eq('animefile_episode', _episodeController.text);

      if (existingEpisodes.isNotEmpty) {
        throw Exception('Episode ${_episodeController.text} already exists in season ${_seasonController.text}');
      }

      // Insert record
      await Supabase.instance.client.from("tbl_animefile").insert({
        'animefile_file': videoUrl,
        'animefile_episode': _episodeController.text,
        'animefile_season': _seasonController.text,
        'anime_id': widget.animeId,
      });

      // Reset form and refresh
      _episodeController.clear();
      _seasonController.clear();
      pickedVideo = null;
      await fetchAnimeFiles();
      setState(() {});

      showSuccessDialog();
    } on PostgrestException catch (e) {
      print('Database error: ${e.message}');
      showSnackbar("Database error: ${e.message}", Colors.red);
    } on Exception catch (e) {
      print('Error: $e');
      showSnackbar(e.toString(), Colors.red);
    }
  }

  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Anime Video Uploaded Successfully!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    // Reset form state
    _episodeController.clear();
    _seasonController.clear();
    pickedVideo = null;
    selectedGenreId = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 43, 43, 43),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5D1E9E),
                        const Color(0xFF5D1E9E),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Upload Anime Episode",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Episode Input
                      _buildInputLabel("Episode Number"),
                      const SizedBox(height: 8),
                      _buildStyledInput(
                        controller: _episodeController,
                        hintText: "Enter episode number",
                        icon: Icons.format_list_numbered,
                      ),
                      const SizedBox(height: 20),

                      // Season Input
                      _buildInputLabel("Season Number"),
                      const SizedBox(height: 8),
                      _buildStyledInput(
                        controller: _seasonController,
                        hintText: "Enter season number",
                        icon: Icons.video_library,
                      ),
                      const SizedBox(height: 20),

                      // Genre Dropdown
                      _buildInputLabel("Genre"),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[600]!,
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedGenreId,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.category,
                              color: const Color(0xFF5D1E9E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          items: genreList.map((genre) {
                            return DropdownMenuItem<String>(
                              value: genre['genre_id'].toString(),
                              child: Text(genre['genre_name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGenreId = value;
                            });
                          },
                          hint: const Text(
                            "Select genre",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // File Upload Section
                      _buildInputLabel("Video File"),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: pickVideo,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                pickedVideo != null
                                    ? Icons.check_circle
                                    : Icons.cloud_upload,
                                size: 48,
                                color: const Color(0xFF5D1E9E),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                pickedVideo != null
                                    ? pickedVideo!.name
                                    : "Click to upload video file",
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          insertAnimeVideo();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 226, 116, 7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Upload",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStyledInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            icon,
            color: const Color.fromARGB(255, 226, 116, 7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> getEpisodesForSeason(int season) {
    return animeFiles
        .where(
            (file) => int.parse(file['animefile_season'].toString()) == season)
        .toList()
      ..sort((a, b) => int.parse(a['animefile_episode'].toString())
          .compareTo(int.parse(b['animefile_episode'].toString())));
  }

  Widget _buildSeasonContent(int season) {
    final seasonEpisodes = getEpisodesForSeason(season);

    if (seasonEpisodes.isEmpty) {
      return const Center(
        child: Text(
          "No episodes in this season",
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: seasonEpisodes.length,
      itemBuilder: (context, index) {
        final episode = seasonEpisodes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.orange.shade50,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 170, 82, 225).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.video_library,
                  color: const Color(0xFF5D1E9E),
                  size: 32,
                ),
              ),
              title: Text(
                'Episode ${episode['animefile_episode']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 43, 43, 43),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => VideoPlayerDialog(
                          videoUrl: episode['animefile_file'],
                          episodeNumber:
                              episode['animefile_episode'].toString(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline,
                        color: Colors.white),
                    label: const Text(
                      'Play',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 142, 76, 207),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () => _deleteAnimeFile(episode['animefile_id']),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF5D1E9E),
              const Color(0xFF5D1E9E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Manage Anime Episodes',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showUploadDialog,
                    icon: const Icon(Icons.upload, color: Colors.black),
                    label: const Text(
                      "Upload Episode",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (seasons.isNotEmpty)
              Container(
                color: Colors.white.withOpacity(0.1),
                child: TabBar(
                  controller: _tabController,
                  tabs: seasons
                      .map((season) => Tab(
                            child: Text(
                              'Season $season',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ))
                      .toList(),
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: seasons.isEmpty
                    ? const Center(
                        child: Text(
                          "No episodes uploaded yet",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: seasons.map((season) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildSeasonContent(season),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget buildDropdown(String label, String? value,
      List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget buildFilePicker() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          pickedVideo != null ? pickedVideo!.name : "Select Video File",
          style: TextStyle(
            color: pickedVideo != null ? Colors.black : Colors.grey,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.upload_file, color: Colors.blue),
          onPressed: pickVideo,
        ),
      ),
    );
  }

  Future<void> _deleteAnimeFile(int fileId) async {
    try {
      // Get file URL before deletion
      final fileData = await Supabase.instance.client
          .from('tbl_animefile')
          .select('animefile_file')
          .eq('animefile_id', fileId)
          .single();

      // Delete from storage first
      if (fileData['animefile_file'] != null) {
        final fileUrl = fileData['animefile_file'].toString();
        final fileName = fileUrl.split('/').last;
        
        try {
          await Supabase.instance.client.storage
              .from('anime')
              .remove([fileName]);
        } on StorageException catch (e) {
          print('Storage deletion error: ${e.message}');
          // Continue with database deletion even if storage deletion fails
        }
      }

      // Delete from database
      await Supabase.instance.client
          .from('tbl_animefile')
          .delete()
          .eq('animefile_id', fileId);

      await fetchAnimeFiles();
      showSnackbar("Episode deleted successfully", Colors.green);
    } on PostgrestException catch (e) {
      print('Database deletion error: ${e.message}');
      showSnackbar("Database error: ${e.message}", Colors.red);
    } catch (e) {
      print('Deletion error: $e');
      showSnackbar("Error deleting episode: $e", Colors.red);
    }
  }
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final String episodeNumber;

  const VideoPlayerDialog({
    Key? key,
    required this.videoUrl,
    required this.episodeNumber,
  }) : super(key: key);

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

    try {
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 43, 43, 43),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 226, 116, 7),
                    Color.fromARGB(255, 196, 128, 32)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Episode ${widget.episodeNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 196, 128, 32),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
