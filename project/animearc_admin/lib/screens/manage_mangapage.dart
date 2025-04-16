import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:html' as html;

class MangaPages extends StatefulWidget {
  final int mangaId;
  const MangaPages({super.key, required this.mangaId});

  @override
  State<MangaPages> createState() => _MangaPagesState();
}

class _MangaPagesState extends State<MangaPages> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pageNumberController = TextEditingController();
  File? _pageImage;
  Uint8List? _webImageBytes;
  String? _imageUrl;
  int? _selectedMangafileId;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _showForm = true;
  List<Map<String, dynamic>> _pages = [];
  List<Map<String, dynamic>> _chapters = [];

  @override
  void initState() {
    super.initState();
    _fetchChapters();
    _fetchPages();
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
        if (_chapters.isNotEmpty) {
          _selectedMangafileId = _chapters[0]['id'];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching chapters: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchPages() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_mangapage')
          .select('*, tbl_mangafile!inner(chapter_number)')
          .eq('mangafile_id', widget.mangaId)
          .order('mangapage_no');

      setState(() {
        _pages = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching pages: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
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
          _imageUrl = html.Url.createObjectUrlFromBlob(file);
          _pageImage = null;
        });
      }
    } else {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pageImage = File(image.path);
          _imageUrl = null;
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _savePage() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_pageImage == null && _webImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chapter and a page image')),
      );
      return;
    }


    setState(() {
      _isLoading = true;
    });

    try {
      String finalImageUrl = '';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'manga_pages/${widget.mangaId}/$fileName';

      if (kIsWeb) {
        await Supabase.instance.client.storage
            .from('manga')
            .uploadBinary(filePath, _webImageBytes!);
      } else {
        await Supabase.instance.client.storage
            .from('manga')
            .upload(filePath, _pageImage!);
      }

      finalImageUrl = Supabase.instance.client.storage
          .from('manga')
          .getPublicUrl(filePath);

      await Supabase.instance.client.from('tbl_mangapage').insert({
        'mangapage_no': int.parse(_pageNumberController.text),
        'mangapage_file': finalImageUrl,
        'mangafile_id': widget.mangaId,
      });

      _pageNumberController.clear();
      setState(() {
        _pageImage = null;
        _webImageBytes = null;
        _imageUrl = null;
      });

      await _fetchPages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page added successfully')),
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

  Future<void> _editPageNumber(Map<String, dynamic> page) async {
    final editController = TextEditingController(text: page['mangapage_no'].toString());
    final pageId = page['id'];
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Page Number'),
        content: TextField(
          controller: editController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Page Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newPageNumber = int.tryParse(editController.text);
              if (newPageNumber == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid page number')),
                );
                return;
              }
              
              // Check for duplicate page number, excluding current page
             
              
              try {
                await Supabase.instance.client
                    .from('tbl_mangapage')
                    .update({'mangapage_no': newPageNumber})
                    .eq('mangapage_id', pageId);
                
                Navigator.of(context).pop();
                await _fetchPages();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Page number updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating page: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageNumberController.dispose();
    super.dispose();
  }

  Widget _buildPageList() {
    if (_pages.isEmpty) {
      return const Center(
        child: Text('No pages added yet'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1,
      ),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => FullScreenImageViewer(
                imageUrl: page['mangapage_file'],
                pageNumber: page['mangapage_no'],
                chapterNumber: page['tbl_mangafile']['chapter_number'],
              ),
            );
          },
          child: Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    page['mangapage_file'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${page['mangapage_no']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _editPageNumber(page),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () async {
                              try {
                                await Supabase.instance.client
                                    .from('tbl_mangapage')
                                    .delete()
                                    .eq('id', page['id']);
                                await _fetchPages();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Page deleted successfully')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error deleting page: ${e.toString()}')),
                                  );
                                }
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pages'),
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
                      controller: _pageNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Page Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter page number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Select Page Image'),
                    ),
                    if (_pageImage != null || _imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: kIsWeb
                            ? Image.network(
                                _imageUrl!,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _pageImage!,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              // if (_formKey.currentState!.validate()) {
                                
                              //   if (_pageImage == null && _webImageBytes == null) {
                              //     ScaffoldMessenger.of(context).showSnackBar(
                              //       const SnackBar(
                              //           content: Text('Please select a page image')),
                              //     );
                              //     return;
                              //   }
                                _savePage();
                              // }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Page'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
            ],
            const Text(
              'Pages List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPageList(),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final int pageNumber;
  final int chapterNumber;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.pageNumber,
    required this.chapterNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error, size: 50),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black54,
              child: Text(
                'Chapter $chapterNumber, Page $pageNumber',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}