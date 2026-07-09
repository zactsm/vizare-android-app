import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _logger = Logger();

  // Controllers
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagInputController = TextEditingController();

  // State
  final List<File> _selectedImages = [];
  File? _selectedModel; // Stores the 3D file (.glb)
  final List<String> _tags = ['bungalow', 'garage']; // Default tags

  bool _isForRent = false;
  bool _isForSale = true;
  bool _isUploading = false;

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
        allowMultiple: true,
      );
      if (!mounted || result == null) {
        return;
      }

      final pickedPaths = result.paths.whereType<String>().toList();
      if (pickedPaths.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedPaths.map(File.new));
        });
      }
    } catch (e) {
      _logger.e("Error picking images", error: e);
    }
  }

  Future<void> _pickModel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      final selectedPath = result?.files.single.path;
      if (!mounted || selectedPath == null) {
        return;
      }

      final file = File(selectedPath);
      final lowerPath = file.path.toLowerCase();
      if (lowerPath.endsWith('.glb') || lowerPath.endsWith('.gltf')) {
        setState(() {
          _selectedModel = file;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a valid .glb 3D file")),
        );
      }
    } catch (e) {
      _logger.e("Error picking model", error: e);
    }
  }

  // --- 2. UPLOAD LOGIC ---

  Future<String?> _uploadToSupabase(File file) =>
      ApiService.uploadPropertyAsset(file);

  // --- 3. SUBMIT LOGIC (Updated) ---

  Future<void> _submitProperty() async {
    // 1. Validation
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image.')),
      );
      return;
    }
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Title and Price.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 2. Upload ALL Images Loop
      List<String> uploadedUrls = [];

      for (File img in _selectedImages) {
        final url = await _uploadToSupabase(img);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      if (uploadedUrls.isEmpty) {
        throw Exception("Failed to upload images. Check internet connection.");
      }

      // 3. Prepare Data
      // Use the first image as the main "cover"
      String coverImageUrl = uploadedUrls.first;
      // Join ALL urls with commas for the gallery
      String galleryString = uploadedUrls.join(",");

      // 4. Upload 3D Model (Optional)
      String modelUrl = '';
      if (_selectedModel != null) {
        final url = await _uploadToSupabase(_selectedModel!);
        if (url != null) {
          modelUrl = url;
        } else {
          throw Exception("Failed to upload 3D Model.");
        }
      }

      // 5. Get User
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) throw Exception("User not logged in.");

      // 6. Send to PHP
      final response = await ApiService.post(
        'add_property.php',
        body: {
          'email': email,
          'name': _titleController.text,
          'location': _locationController.text,
          'price': _priceController.text,
          'description': _descriptionController.text,
          'image_path': coverImageUrl,    // Main cover
          'gallery_images': galleryString, // Comma separated list
          'model_path': modelUrl,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] != null && data['message'].toString().contains("successfully")) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Property posted!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception(data['message'] ?? "Unknown server error");
        }
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }

    } catch (e) {
      _logger.e("Submit error", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
            // Title
            _buildGradientTitle("Add New\nProperty"),
            const SizedBox(height: 24),

            // Image Gallery
            _buildImageGallery(),
            const SizedBox(height: 16),

            // 3D Model Picker UI
            GestureDetector(
              onTap: _pickModel,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: (0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _selectedModel != null ? Colors.green : Colors.white.withValues(alpha: (0.2))
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                        Icons.view_in_ar,
                        color: _selectedModel != null ? Colors.green : Colors.white54
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          _selectedModel != null
                              ? "Model ready: ${path.basename(_selectedModel!.path)}"
                              : "Upload 3D Model (.glb)",
                          style: TextStyle(
                            color: _selectedModel != null ? Colors.green : Colors.white54,
                            fontFamily: 'Inter',
                            fontWeight: _selectedModel != null ? FontWeight.bold : FontWeight.normal,
                          )
                      ),
                    ),
                    if (_selectedModel != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedModel = null),
                        child: const Icon(Icons.close, color: Colors.redAccent),
                      )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title Field
            _buildLabel("Title"),
            _buildTextField(controller: _titleController, hint: "Apartment #1 Residency"),

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
                          hint: "RM450,000",
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
                      setState(() {
                        _isForRent = val!;
                        if(_isForRent) _isForSale = false;
                      });
                    }),
                    const SizedBox(height: 8),
                    _buildCheckbox("For sale", _isForSale, (val) {
                      setState(() {
                        _isForSale = val!;
                        if(_isForSale) _isForRent = false;
                      });
                    }),
                    const SizedBox(height: 3),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            _buildLabel("Description"),
            _buildTextField(
              controller: _descriptionController,
              hint: "Lorem ipsum dolor sit amet...",
              maxLines: 6,
            ),

            const SizedBox(height: 16),

            // Location
            _buildLabel("Location"),
            _buildTextField(controller: _locationController, hint: "Shah Alam, Malaysia"),

            const SizedBox(height: 16),

            // Tags
            _buildLabel("Tags"),
            _buildTagsSection(),

            const SizedBox(height: 40),

            // Bottom Buttons
            Row(
              children: [
                // Discard
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3D00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Discard", style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                // Save
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitProperty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E17EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUploading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save", style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
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

  Widget _buildGradientTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF5A62F1), Color(0xFF548FEE), Color(0xFF9FD0F6), Color(0xFFD6B3F9), Color(0xFFB191FA)],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(fontSize: 32, fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
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

  Widget _buildTextField({required TextEditingController controller, String? hint, int maxLines = 1, TextInputType? keyboardType}) {
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
          hintText: hint,
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

  Widget _buildImageGallery() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: (0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, color: Colors.white54, size: 40),
              SizedBox(height: 8),
              Text("Add Photos", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: (0.1)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 40),
              ),
            );
          }

          return Stack(
            children: [
              Container(
                width: 180,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(_selectedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
