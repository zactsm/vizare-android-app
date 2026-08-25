import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
        SnackBar(
          content: Text('Please enter an inquiry message.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
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
          SnackBar(
            content: Text(
              'Inquiry sent! The estate advisor will respond directly.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: VizareColors.emeraldGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e("Error sending inquiry", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transmit inquiry: $e',
                style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const VizareAppBar(
          title: 'Private Inquiry',
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estate Concierge Contact',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Direct communication channel with the listing owner and representative.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: VizareColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Property Target Glass Card
                VisionGlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.property.imagePath,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: VizareColors.obsidianSurface,
                            child: const Icon(
                              Icons.home_work_rounded,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.property.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.property.location,
                              style: GoogleFonts.inter(
                                color: VizareColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.property.price,
                              style: GoogleFonts.poppins(
                                color: VizareColors.champagneGold,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                VisionGlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Sender Identity'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: VizareColors.obsidianSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alternate_email_rounded,
                              color: VizareColors.champagneGold,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _userEmail,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Message to Homeowner'),
                      Container(
                        decoration: BoxDecoration(
                          color: VizareColors.obsidianSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 6,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Inquire regarding inspection schedules, spatial dimensions, acquisition details...',
                            hintStyle: GoogleFonts.inter(
                              color: VizareColors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                LuxuryGradientButton(
                  text: 'Send Direct Inquiry',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submitInquiry,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: VizareColors.champagneGold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
