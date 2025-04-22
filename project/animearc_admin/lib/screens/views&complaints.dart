import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  List<Map<String, dynamic>> complaints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
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
            *,
            tbl_user (
              user_name,
              user_email
            )
          ''')
          .order('complaint_date', ascending: false);

      print('Fetched complaints: $response'); // Debug print

      if (mounted) {
        setState(() {
          complaints = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching complaints: $error'); // Debug print
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
            'complaint_reply': reply,
            'complaint_status': 'Resolved'
          })
          .eq('complaint_id', complaintId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent successfully!')),
      );
      
      fetchComplaints(); // Refresh the list
    } catch (error) {
      print('Error updating complaint: $error'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reply: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: fetchComplaints,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (complaints.isEmpty) {
      return const Center(
        child: Text('No complaints found'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchComplaints,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchComplaints,
        child: ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                title: Text(complaint['complaint_title'] ?? 'No Title'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: ${complaint['tbl_user']?['user_name'] ?? 'Unknown User'}'),
                    Text('Date: ${complaint['complaint_date'] ?? 'Unknown Date'}'),
                    Text(
                      'Status: ${complaint['complaint_status'] ?? 'Pending'}',
                      style: TextStyle(
                        color: complaint['complaint_status'] == 'Resolved' 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(complaint['complaint_content'] ?? 'No Content'),
                        if (complaint['complaint_screenshot'] != null) ...[
                          const SizedBox(height: 8),
                          Image.network(
                            complaint['complaint_screenshot'],
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return const Text('Error loading image');
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (complaint['complaint_reply'] != null)
                          Text(
                            'Reply: ${complaint['complaint_reply']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (complaint['complaint_status'] != 'Resolved')
                          ElevatedButton(
                            onPressed: () {
                              final replyController = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Reply to Complaint'),
                                  content: TextField(
                                    controller: replyController,
                                    decoration: const InputDecoration(
                                      labelText: 'Your Reply',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
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
                                      child: const Text('Send Reply'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Reply'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}