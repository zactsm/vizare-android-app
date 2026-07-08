import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/models/property_model.dart';

class EditPropertyPage extends StatefulWidget {
  final Property property; // The property being edited

  const EditPropertyPage({super.key, required this.property});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _logger = Logger();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  final _tagInputController = TextEditingController();

  // State
  List<File> _newSelectedImages = []; // Only for NEW files
  List<String> _tags = ['lorem', 'ipsum'];

  bool _isForRent = false;
  bool _isForSale = true;
  bool _isUploading = false;

  // --- ☁️ CLOUDINARY CONFIG ---
  final String _cloudName = ApiService.cloudinaryCloudName;
  final String _uploadPreset = ApiService.cloudinaryUploadPreset;

  @override
  void initState() {
    super.initState();
    // PRE-FILL DATA FROM EXISTING PROPERTY
    _titleController = TextEditingController(text: widget.property.name);
    // Remove "RM " prefix if you store it in DB, or just keep it raw
    _priceController = TextEditingController(text: widget.property.price);
    _descriptionController = TextEditingController(text: widget.property.description);
    _locationController = TextEditingController(text: widget.property.location);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  // --- 1. PICKERS ---

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false, // Keeping it simple: replace the single cover image
      );
      if (result != null) {
        setState(() {
          _newSelectedImages = [File(result.files.single.path!)];
        });
      }
    } catch (e) {
      _logger.e("Error picking images", error: e);
    }
  }

  // --- 2. UPLOAD LOGIC ---

  Future<String?> _uploadToCloudinary(File image) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData.body);
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      _logger.e("Upload error", error: e);
      return null;
    }
  }

  // --- 3. SUBMIT LOGIC (UPDATE) ---

  Future<void> _updateProperty() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Price cannot be empty.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String finalImageUrl = widget.property.imagePath; // Default to OLD URL

      // A. If a NEW image was picked, upload it
      if (_newSelectedImages.isNotEmpty) {
        final newUrl = await _uploadToCloudinary(_newSelectedImages.first);
        if (newUrl != null) {
          finalImageUrl = newUrl;
        } else {
          throw Exception("Failed to upload new image.");
        }
      }

      // B. Get User
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) throw Exception("User not logged in");

      // C. Send to PHP (Edit Endpoint)
      final response = await ApiService.post(
        'edit_property.php',
        body: {
          'email': email,
          'property_id': widget.property.id.toString(), // Critical
          'name': _titleController.text,
          'location': _locationController.text,
          'price': _priceController.text,
          'description': _descriptionController.text,
          'image_path': finalImageUrl, // Sends either old or new URL
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property updated!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Return true to refresh
        }
      } else {
        throw Exception("Server error: ${response.body}");
      }

    } catch (e) {
      _logger.e("Update error", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update property.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradientTitle("Edit Property"),
            const SizedBox(height: 24),

            // Image Gallery (Modified for Edit)
            _buildImagePreview(),
            const SizedBox(height: 24),

            // Title Field
            _buildLabel("Title"),
            _buildTextField(controller: _titleController),

            const SizedBox(height: 16),

            // Price and Checkboxes Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Price"),
                      _buildTextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckbox("For rent", _isForRent, (val) {
                      setState(() { _isForRent = val!; if(_isForRent) _isForSale = false; });
                    }),
                    const SizedBox(height: 8),
                    _buildCheckbox("For sale", _isForSale, (val) {
                      setState(() { _isForSale = val!; if(_isForSale) _isForRent = false; });
                    }),
                    const SizedBox(height: 3),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildLabel("Description"),
            _buildTextField(controller: _descriptionController, maxLines: 6),

            const SizedBox(height: 16),

            _buildLabel("Location"),
            _buildTextField(controller: _locationController),

            const SizedBox(height: 16),

            _buildLabel("Tags"),
            _buildTagsSection(),

            const SizedBox(height: 40),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3D00), // Orange/Red
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _updateProperty, // Call Update
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E17EB), // Purple
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUploading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Update", style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildImagePreview() {
    // Logic: Show NEW file if picked, else show EXISTING network url
    ImageProvider imageProvider;
    if (_newSelectedImages.isNotEmpty) {
      imageProvider = FileImage(_newSelectedImages.first);
    } else {
      imageProvider = NetworkImage(widget.property.imagePath);
    }

    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: (0.1)),
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // "Change Photo" Button overlay
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: (0.7)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text("Change Photo", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildGradientTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF5A62F1), Color(0xFF548FEE), Color(0xFF9FD0F6), Color(0xFFD6B3F9), Color(0xFFB191FA)],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(fontSize: 32, fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white, height: 1.05),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withValues(alpha: (0.5)), fontFamily: 'Inter', fontSize: 12),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            checkColor: Colors.black,
            activeColor: Colors.white,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return Colors.transparent;
            }),
            side: const BorderSide(color: Colors.white, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 14)),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: Colors.grey[600],
              deleteIcon: const Icon(Icons.cancel, size: 14, color: Colors.white),
              onDeleted: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
              padding: const EdgeInsets.all(0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            )).toList(),
          ),
          if (_tags.isNotEmpty) const SizedBox(height: 8),
          TextField(
            controller: _tagInputController,
            decoration: const InputDecoration(
              hintText: "Type tag and press enter...",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
              isDense: true,
              border: InputBorder.none,
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                setState(() {
                  _tags.add(val.trim());
                  _tagInputController.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}