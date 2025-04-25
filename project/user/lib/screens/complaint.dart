import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

// Add this error handler class at the top of the file
class ComplaintErrorHandler {
  static void logError(String method, dynamic error, StackTrace stackTrace) {
    print('Error in $method: $error');
    print('Stack trace: $stackTrace');
  }
}

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
  List<Map<String, dynamic>>? complaintHistory;

  @override
  void initState() {
    try {
      super.initState();
      _fetchExistingComplaints();
    } catch (e, stackTrace) {
      ComplaintErrorHandler.logError('initState', e, stackTrace);
    }
  }

  Future<void> _fetchExistingComplaints() async {
    try {
      final response = await supabase
          .from('tbl_complaint')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('complaint_date', ascending: false);

      if (mounted && response != null) {
        setState(() {
          complaintHistory = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e, stackTrace) {
      ComplaintErrorHandler.logError('_fetchExistingComplaints', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching complaints: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
        allowCompression: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final file = result.files.first;
        try {
          final String fileName = 'complaint_${DateTime.now().millisecondsSinceEpoch}${file.extension}';

          // Upload to Supabase storage
          try {
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
          } catch (uploadError, uploadStackTrace) {
            ComplaintErrorHandler.logError('_pickAndUploadImage (upload)', uploadError, uploadStackTrace);
            throw Exception('Failed to upload image: $uploadError');
          }
        } catch (fileError, fileStackTrace) {
          ComplaintErrorHandler.logError('_pickAndUploadImage (file processing)', fileError, fileStackTrace);
          throw Exception('Failed to process file: $fileError');
        }
      }
    } catch (e, stackTrace) {
      ComplaintErrorHandler.logError('_pickAndUploadImage', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error handling image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitComplaint() async {
    try {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _isLoading = true);

      // Validate inputs
      if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
        throw Exception('Please fill in all required fields');
      }

      try {
        await supabase.from('complaints').insert({
          'complaint_title': _titleController.text.trim(),
          'complaint_content': _contentController.text.trim(),
          'complaint_status': 'pending',
          'complaint_date': DateTime.now().toIso8601String(),
          'complaint_screenshot': _imageUrl,
          'user_id': supabase.auth.currentUser!.id,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complaint submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (dbError, dbStackTrace) {
        ComplaintErrorHandler.logError('_submitComplaint (database)', dbError, dbStackTrace);
        throw Exception('Failed to submit complaint: $dbError');
      }
    } catch (e, stackTrace) {
      ComplaintErrorHandler.logError('_submitComplaint', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildComplaintHistory() {
    if (complaintHistory == null || complaintHistory!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Complaint History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.purple[200],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: complaintHistory!.length,
          itemBuilder: (context, index) {
            final complaint = complaintHistory![index];
            final DateTime complaintDate = DateTime.parse(complaint['complaint_date']);
            final String formattedDate = '${complaintDate.day}/${complaintDate.month}/${complaintDate.year}';
            
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _getStatusColor(complaint['complaint_status']).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  complaint['complaint_title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(complaint['complaint_status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        complaint['complaint_status'].toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(complaint['complaint_status']),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(formattedDate, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(complaint['complaint_content']),
                        if (complaint['complaint_screenshot'] != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              complaint['complaint_screenshot'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        if (complaint['complaint_reply'] != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.admin_panel_settings, 
                                      color: Colors.purple,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Admin Reply',
                                      style: TextStyle(
                                        color: Colors.purple[200],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(complaint['complaint_reply']),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildComplaintHistory(),
            const SizedBox(height: 16),
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
    try {
      _titleController.dispose();
      _contentController.dispose();
      super.dispose();
    } catch (e, stackTrace) {
      ComplaintErrorHandler.logError('dispose', e, stackTrace);
    }
  }
}