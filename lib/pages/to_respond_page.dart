import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ToRespondPage extends StatefulWidget {
  const ToRespondPage({super.key});

  @override
  State<ToRespondPage> createState() => _ToRespondPageState();
}

class _ToRespondPageState extends State<ToRespondPage> {
  List<Map<String, dynamic>> _inquiries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
  }

  Future<void> _fetchInquiries() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.get('get_inquiries.php');
      if (response.statusCode != 200) {
        throw Exception('Could not load inquiries: ${response.body}');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _inquiries = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : _buildInquiryList(),
    );
  }

  Widget _buildInquiryList() {
    if (_inquiries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No inquiries yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInquiries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inquiries.length,
        itemBuilder: (context, index) {
          final data = _inquiries[index];
          var timeString = 'Just now';
          final createdAt = DateTime.tryParse(
            data['created_at']?.toString() ?? '',
          );
          if (createdAt != null) {
            timeString = DateFormat('MMM d, h:mm a').format(createdAt.toLocal());
          }

          return Card(
            color: Colors.white.withValues(alpha: 0.05),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                data['property_name'] ?? 'Unknown Property',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "From: ${data['buyer_email']}",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['message'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeString,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
              onTap: () => _showInquiryDetails(
                context,
                data,
                data['id'].toString(),
              ),
            ),
          );
        },
      ),
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
                    backgroundColor: const Color(0xFFFFF200),
                    foregroundColor: const Color(0xFF0D0D0D),
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
