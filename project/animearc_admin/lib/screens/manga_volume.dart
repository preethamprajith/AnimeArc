import 'package:animearc_admin/screens/manage_mangapage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // For Uint8List
import 'dart:html' as html; // For web-specific file handling

class ManageVolume extends StatefulWidget {
  final int mangaId;
  const ManageVolume({super.key, required this.mangaId});

  @override
  State<ManageVolume> createState() => _ManageVolumeState();
}

class _ManageVolumeState extends State<ManageVolume> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _chapterNumberController = TextEditingController();
  DateTime? _releaseDate;
  File? _posterImage; // Used for mobile
  Uint8List? _webImageBytes; // Used for web
  String? _imageUrl; // Preview URL for web
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Map<String, dynamic>> _chapters = [];

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_mangafile')
          .select()
          .eq('manga_id', widget.mangaId)
          .order('chapter_number');

      setState(() {
        _chapters = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching chapters: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Web-specific file picker
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();

      await input.onChange.first;
      if (input.files!.isNotEmpty) {
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        setState(() {
          _webImageBytes = reader.result as Uint8List;
          _imageUrl = html.Url.createObjectUrlFromBlob(file); // For preview
          _posterImage = null; // Clear mobile file
        });
      }
    } else {
      // Mobile-specific image picker
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _posterImage = File(image.path);
          _imageUrl = null; // Clear web preview
          _webImageBytes = null; // Clear web bytes
        });
      }
    }
  }

  Future<void> _saveChapter() async {
    if (!_formKey.currentState!.validate()) return;
    if (_releaseDate == null || (_posterImage == null && _webImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a poster image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String finalImageUrl = '';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png'; // Default to .png for simplicity
      final filePath = 'manga_chapters/${widget.mangaId}/$fileName';

      if (kIsWeb) {
        // Web: Upload raw bytes
        await Supabase.instance.client.storage
            .from('manga')
            .uploadBinary(filePath, _webImageBytes!);
      } else {
        // Mobile: Upload File
        await Supabase.instance.client.storage
            .from('manga')
            .upload(filePath, _posterImage!);
      }

      // Get the public URL
      finalImageUrl = Supabase.instance.client.storage
          .from('manga')
          .getPublicUrl(filePath);

      // Insert data into tbl_mangafile
      await Supabase.instance.client.from('tbl_mangafile').insert({
        'chapter_number': int.parse(_chapterNumberController.text),
        'chapter_file': finalImageUrl,
        'release_date': _releaseDate!.toIso8601String(),
        'manga_id': widget.mangaId,
      });

      // Clear form and refresh chapters
      _chapterNumberController.clear();
      setState(() {
        _releaseDate = null;
        _posterImage = null;
        _webImageBytes = null;
        _imageUrl = null;
      });

      await _fetchChapters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to show the add pages dialog
  @override
  void dispose() {
    _chapterNumberController.dispose();
    super.dispose();
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
            // Header
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Manage Manga Chapters',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddChapterDialog,
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text(
                      "Add Chapter",
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

            // Content
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
                child: _chapters.isEmpty
                    ? const Center(
                        child: Text(
                          "No chapters added yet",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
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
                                contentPadding: const EdgeInsets.all(12),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    chapter['chapter_file'],
                                    width: 60,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 60,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'Chapter ${chapter['chapter_number']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                subtitle: Text(
                                  'Release Date: ${DateTime.parse(chapter['release_date']).toString().split(' ')[0]}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MangaPages(
                                              mangaId: chapter['mangafile_id'],
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Add Pages',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 158, 58, 225),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () => _deleteChapter(
                                        chapter['mangafile_id'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChapterDialog() {
    _chapterNumberController.clear();
    _releaseDate = null;
    _posterImage = null;
    _webImageBytes = null;
    _imageUrl = null;

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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 128, 20, 216),
                          Color.fromARGB(255, 132, 72, 211)
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
                          "Add New Chapter",
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
                        _buildInputLabel("Chapter Number"),
                        const SizedBox(height: 8),
                        _buildStyledInput(
                          controller: _chapterNumberController,
                          hintText: "Enter chapter number",
                          icon: Icons.format_list_numbered,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter chapter number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel("Release Date"),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _releaseDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _releaseDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: const Color.fromARGB(255, 84, 20, 152),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _releaseDate == null
                                      ? "Select release date"
                                      : _releaseDate!
                                          .toString()
                                          .split(' ')[0],
                                  style: TextStyle(
                                    color: _releaseDate == null
                                        ? Colors.grey[500]
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel("Chapter Cover"),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 147, 47, 213),
                                width: 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (_imageUrl != null || _posterImage != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            _imageUrl!,
                                            height: 150,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            _posterImage!,
                                            height: 150,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.cloud_upload,
                                    size: 48,
                                    color:
                                        const Color.fromARGB(255, 123, 23, 190),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Click to upload cover image",
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
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
                          onPressed: _isLoading ? null : () => _saveChapter(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 123, 31, 209),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Save Chapter",
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(
          icon,
          color: const Color.fromARGB(255, 140, 40, 212),
        ),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 98, 24, 155),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _deleteChapter(int chapterId) async {
    try {
      await Supabase.instance.client
          .from('tbl_mangafile')
          .delete()
          .eq('mangafile_id', chapterId);
      
      await _fetchChapters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapter deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting chapter: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
