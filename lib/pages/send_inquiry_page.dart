import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class SendInquiryPage extends StatefulWidget {
  final Property property;

  const SendInquiryPage({super.key, required this.property});

  @override
  State<SendInquiryPage> createState() => _SendInquiryPageState();
}

class _SendInquiryPageState extends State<SendInquiryPage> {
  final _messageController = TextEditingController();
  final _logger = Logger();
  bool _isSubmitting = false;
  String _userEmail = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('user_email') ?? 'Anonymous';
    });
  }

  Future<void> _submitInquiry() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.post(
        'send_inquiry.php',
        body: {
          'property_id': widget.property.id.toString(),
          'message': _messageController.text.trim(),
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Server rejected inquiry: ${response.body}');
      }

      _logger.i("Inquiry saved to Supabase");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inquiry sent! The homeowner will see it in their app.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e("Error sending inquiry", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send inquiry. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pitch Black background
      body: AbstractBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom top section instead of standard AppBar (Back Navigation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INQUIRY',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: pastelPurple,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Send inquiry',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // "From" Box (Chunky Solid Container)
                      const Text(
                        'From:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121214), // Solid dark grey card block
                          border: Border.all(color: pastelPurple, width: 2.0), // High-contrast border
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userEmail.split('@')[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '($_userEmail)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // "Message" Text Area
                      const Text(
                        'Message:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFF121214), // Solid card block
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Message here...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontFamily: 'Poppins'),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Submit Button (Wise Style: Solid Accent filled shape, black text)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitInquiry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pastelPurple,
                            foregroundColor: const Color(0xFF000000),
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Color(0xFF000000))
                              : const Text(
                                  'SUBMIT INQUIRY',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
