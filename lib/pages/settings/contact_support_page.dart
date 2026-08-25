import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final _logger = Logger();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<PlatformFile> _attachedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      _logger.e("Error picking files", error: e);
    }
  }

  Future<void> _submitSupportTicket() async {
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in both subject and description.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
      final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
      final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? 'Anonymous';

      final List<String> fileUrls = [];
      for (var file in _attachedFiles) {
        final downloadUrl = await ApiService.uploadSupportAttachment(file);
        if (downloadUrl != null) {
          fileUrls.add(downloadUrl);
        }
      }

      final ticketResponse = await ApiService.post(
        'create_support_ticket.php',
        body: {
          'subject': _subjectController.text.trim(),
          'description': _descriptionController.text.trim(),
          'attachment_urls': jsonEncode(fileUrls),
        },
      );
      if (ticketResponse.statusCode != 200) {
        throw Exception('Could not save ticket: ${ticketResponse.body}');
      }

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final String linksString =
          fileUrls.isEmpty ? "No attachments" : fileUrls.join("\n");

      if (serviceId.isNotEmpty && publicKey.isNotEmpty) {
        try {
          await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': publicKey,
              'template_params': {
                'user_email': userEmail,
                'subject': _subjectController.text.trim(),
                'description': _descriptionController.text.trim(),
                'attachment_links': linksString,
              }
            }),
          ).timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Support ticket submitted! Our team will contact you shortly.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: VizareColors.emeraldGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e("Error submitting ticket", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission error: $e', style: GoogleFonts.inter()),
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
          title: 'Contact Support',
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Support',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Submit architectural inquiries, technical assistance, or property portfolio requests.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: VizareColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                VisionGlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextFieldLabel('Subject'),
                      _buildInput(
                        controller: _subjectController,
                        hintText: 'e.g. 3D AR Model Viewport Inquiry',
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildTextFieldLabel('Description'),
                      _buildInput(
                        controller: _descriptionController,
                        hintText: 'Provide details regarding your issue or inquiry...',
                        icon: Icons.description_rounded,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                      _buildTextFieldLabel('Attachments (Optional)'),
                      GestureDetector(
                        onTap: _isSubmitting ? null : _pickFiles,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: VizareColors.champagneGold
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                color: VizareColors.champagneGold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Select Files / Screenshots',
                                style: GoogleFonts.inter(
                                  color: VizareColors.champagneGold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_attachedFiles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _attachedFiles.map((file) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: VizareColors.obsidianSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    file.name,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _attachedFiles.remove(file)),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitSupportTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VizareColors.champagneGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: VizareColors.champagneGold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: VizareColors.obsidianSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: VizareColors.champagneGold.withValues(alpha: 0.7),
            size: 20,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: VizareColors.textMuted,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
