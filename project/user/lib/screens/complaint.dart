import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class Complaint extends StatefulWidget {
  const Complaint({super.key});

  @override
  State<Complaint> createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;
  PlatformFile? pickedImage;
  Map<String, dynamic>? complaintDetails;

  @override
  void initState() {
    super.initState();
    _fetchExistingComplaints();
  }

  Future<void> _fetchExistingComplaints() async {
    try {
      final response = await supabase
          .from('complaints')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('complaint_date', ascending: false)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          complaintDetails = response;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching complaints: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      // Optimize file picker configuration
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Load file bytes directly
        allowCompression: true, // Enable compression
        // Removed invalid parameters
      );

      if (result != null && result.files.first.bytes != null) {
        final file = result.files.first;
        final String fileName = 'complaint_${DateTime.now().millisecondsSinceEpoch}${file.extension}';

        // Upload to Supabase bucket with optimized settings
        await supabase.storage
            .from('complaint')
            .uploadBinary(
              fileName,
              file.bytes!,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        final String publicUrl = supabase.storage
            .from('complaint')
            .getPublicUrl(fileName);

        if (mounted) {
          setState(() {
            pickedImage = file;
            _selectedImage = File(file.path!);
            _imageUrl = publicUrl;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      await supabase.from('complaints').insert({
        'complaint_title': _titleController.text,
        'complaint_content': _contentController.text,
        'complaint_status': 'pending',
        'complaint_date': DateTime.now().toIso8601String(),
        'complaint_screenshot': _imageUrl,
        'user_id': supabase.auth.currentUser!.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting complaint: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Complaint'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Optimize scrolling
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (complaintDetails != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous Complaint Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Title: ${complaintDetails!['complaint_title']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Status: ${complaintDetails!['complaint_status']}'),
                      if (complaintDetails!['complaint_reply'] != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Admin Reply:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(complaintDetails!['complaint_reply']),
                        ),
                      ],
                      if (complaintDetails!['complaint_screenshot'] != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            complaintDetails!['complaint_screenshot'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary( // Add RepaintBoundary for better performance
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Complaint Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter a title' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contentController,
                              decoration: const InputDecoration(
                                labelText: 'Complaint Description',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 5,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter a description' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: _isLoading ? null : _pickAndUploadImage,
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          child: _selectedImage != null
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                      cacheWidth: 800, // Optimize image loading
                                      cacheHeight: 600,
                                    ),
                                    if (_isLoading)
                                      Container(
                                        color: Colors.black45,
                                        child: const CircularProgressIndicator(),
                                      ),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload, size: 50),
                                    Text('Tap to upload screenshot'),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Complaint'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}