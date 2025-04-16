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
  bool _showForm = true;
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

  Widget _buildChapterList() {
    if (_chapters.isEmpty) {
      return const Center(
        child: Text('No chapters added yet'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chapters.length,
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              ListTile(
                leading: Image.network(
                  chapter['chapter_file'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text('Chapter ${chapter['chapter_number']}'),
                subtitle: Text(
                  'Release Date: ${DateTime.parse(chapter['release_date']).toString().split(' ')[0]}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate),
                      tooltip: 'Add Pages',
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => MangaPages(mangaId: chapter['mangafile_id'])
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Chapter',
                      onPressed: () async {
                        try {
                          await Supabase.instance.client
                              .from('tbl_mangafile')
                              .delete()
                              .eq('id', chapter['mangafile_id']);
                          await _fetchChapters();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chapter deleted successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error deleting chapter: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Chapters'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showForm = !_showForm;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showForm) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _chapterNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Chapter Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter chapter number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _releaseDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Release Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _releaseDate != null
                              ? '${_releaseDate!.day}/${_releaseDate!.month}/${_releaseDate!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Select Poster Image'),
                    ),
                    if (_posterImage != null || _imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: kIsWeb
                            ? Image.network(
                                _imageUrl!,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _posterImage!,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                if (_releaseDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please select release date')),
                                  );
                                  return;
                                }
                                if (_posterImage == null && _webImageBytes == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please select poster image')),
                                  );
                                  return;
                                }
                                _saveChapter();
                              }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Chapter'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
            ],
            const Text(
              'Chapters List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildChapterList(),
          ],
        ),
      ),
    );
  }
}