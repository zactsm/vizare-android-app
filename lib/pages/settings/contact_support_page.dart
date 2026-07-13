import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // For EmailJS
import 'dart:convert'; // For jsonEncode
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:untitled/pages/utils/api_service.dart';

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logger = Logger();

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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      _logger.e('Error picking files', error: e);
    }
  }

  Future<void> _submitSupportTicket() async {
    // --- 1. CONFIGURATION ---
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

    // --- 2. VALIDATION ---
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a subject and description.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // --- 3. GET USER EMAIL ---
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? 'Anonymous';

      // --- 4. UPLOAD FILES TO SUPABASE STORAGE ---
      List<String> fileUrls = [];
      if (_attachedFiles.isNotEmpty) {
        for (var file in _attachedFiles) {
          final downloadUrl = await ApiService.uploadSupportAttachment(file);
          if (downloadUrl == null) {
            throw Exception('An attachment could not be uploaded.');
          }
          fileUrls.add(downloadUrl);
        }
      }

      // --- 5. SAVE TO SUPABASE THROUGH THE AUTHENTICATED API ---
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

      // --- 6. SEND EMAIL VIA EMAILJS ---
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      // Format the links for the email body
      String linksString = fileUrls.isEmpty
          ? "No attachments"
          : fileUrls.join("\n");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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
      );

      if (response.statusCode == 200) {
        _logger.i("Email sent successfully via EmailJS");
      } else {
        _logger.w("EmailJS Failed: ${response.body}");
        // The ticket remains safely stored in Supabase.
      }

      // --- 7. SUCCESS UI ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('Support ticket received! We will contact you shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e("Error submitting ticket", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              _buildTextFieldLabel('Subject*'),
              _buildTextField(
                controller: _subjectController,
                hintText: 'Subject here...',
              ),
              const SizedBox(height: 24),

              _buildTextFieldLabel('Description*'),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Description here...',
                maxLines: 6,
              ),
              const SizedBox(height: 24),

              _buildTextFieldLabel('Attachments'),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickFiles,
                icon: const Icon(Icons.attach_file, color: Colors.white),
                label: const Text(
                  'Attach files',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),

              if (_attachedFiles.isNotEmpty) _buildAttachedFilesList(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(26.0, 16.0, 26.0, 26.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitSupportTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDF00FF),
              foregroundColor: const Color(0xFF0D0D0D),
              disabledBackgroundColor: Colors.grey[900],
              disabledForegroundColor: Colors.white30,
              minimumSize: const Size(200, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Text(
              'Submit',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAttachedFilesList() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _attachedFiles.map((file) {
          return Chip(
            label: Text(
              file.name,
              style: const TextStyle(
                  fontFamily: 'Poppins', color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            onDeleted: () {
              setState(() {
                _attachedFiles.remove(file);
              });
            },
            deleteIconColor: Colors.black54,
          );
        }).toList(),
      ),
    );
  }
}
