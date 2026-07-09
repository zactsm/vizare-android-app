import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart'; // ensure intl is in pubspec.yaml
import 'package:url_launcher/url_launcher.dart';

class ToRespondPage extends StatefulWidget {
  const ToRespondPage({super.key});

  @override
  State<ToRespondPage> createState() => _ToRespondPageState();
}

class _ToRespondPageState extends State<ToRespondPage> {
  int? _myUserId;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchMyUserId();
  }

  // 1. Get My MySQL ID so I can find my messages
  Future<void> _fetchMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email != null) {
      try {
        final response = await ApiService.get('get_user_profile.php', {'email': email});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _myUserId = data['id']; // This relies on Step 1 being done!
            _isLoadingUser = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching user ID: $e");
      }
    }
    // If failed, stop loading anyway so we don't hang
    if (mounted && _myUserId == null) setState(() => _isLoadingUser = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Inquiries', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _myUserId == null
          ? const Center(child: Text("Could not verify user identity.", style: TextStyle(color: Colors.grey)))
          : _buildInquiryList(),
    );
  }

  Widget _buildInquiryList() {
    // 2. Listen to Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'vizare-native')
          .collection('inquiries')
          .where('homeowner_id', isEqualTo: _myUserId) // Filter by MY ID
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('No inquiries yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            // Format Timestamp
            String timeString = "Just now";
            if (data['timestamp'] != null) {
              final ts = (data['timestamp'] as Timestamp).toDate();
              timeString = DateFormat('MMM d, h:mm a').format(ts);
            }

            return Card(
              color: Colors.white.withValues(alpha: (0.05)),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  data['property_name'] ?? 'Unknown Property',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("From: ${data['buyer_email']}", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      data['message'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(timeString, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                ),
                onTap: () {
                  // TODO: Navigate to full chat/detail view
                  _showInquiryDetails(context, data, docId);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showInquiryDetails(BuildContext context, Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data['property_name'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text("Buyer Email:", style: TextStyle(color: Colors.grey)),
              Text(data['buyer_email'], style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              const Text("Message:", style: TextStyle(color: Colors.grey)),
              Text(data['message'], style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6B3F9),
                    foregroundColor: const Color(0xFF121212),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final String recipient = data['buyer_email'];
                    final String subject = 'Re: Inquiry about ${data['property_name']}';
                    final String body = '\n\n\n--- Original Message ---\nFrom: $recipient\n${data['message']}';

                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: recipient,
                      query: _encodeQueryParameters(<String, String>{
                        'subject': subject,
                        'body': body,
                      }),
                    );
                    
                    try {
                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(emailLaunchUri);
                      } else {
                        await launchUrl(emailLaunchUri);
                      }
                    } catch (e) {
                      debugPrint("Could not launch email app: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Could not open email app.")),
                        );
                      }
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Reply via Email", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Helper to properly encode spaces and special characters for URLs
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}