import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';
import 'package:untitled/models/property_model.dart';

class EditPropertyPage extends StatefulWidget {
  final Property property;

  const EditPropertyPage({super.key, required this.property});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _logger = Logger();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  final _tagInputController = TextEditingController();

  List<PlatformFile> _newSelectedImages = [];
  final List<String> _tags = ['luxury', 'renovated', 'prime-location'];

  bool _isForRent = false;
  bool _isForSale = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property.name);
    _priceController = TextEditingController(text: widget.property.price);
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _locationController =
        TextEditingController(text: widget.property.location);
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

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final selectedFile = result?.files.single;
      if (!mounted || selectedFile == null) return;

      setState(() {
        _newSelectedImages = [selectedFile];
      });
    } catch (e) {
      _logger.e("Error picking images", error: e);
    }
  }

  Future<String?> _uploadToSupabase(PlatformFile image) =>
      ApiService.uploadPropertyAsset(image);

  Future<void> _updateProperty() async {
    if (_titleController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Title and Price cannot be empty.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final previousImageUrl = widget.property.imagePath;
      String finalImageUrl = widget.property.imagePath;

      if (_newSelectedImages.isNotEmpty) {
        final newUrl = await _uploadToSupabase(_newSelectedImages.first);
        if (newUrl != null) {
          finalImageUrl = newUrl;
        } else {
          throw Exception("Failed to upload new image.");
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) throw Exception("User not logged in");

      final response = await ApiService.post(
        'edit_property.php',
        body: {
          'email': email,
          'property_id': widget.property.id.toString(),
          'name': _titleController.text.trim(),
          'location': _locationController.text.trim(),
          'price': _priceController.text.trim(),
          'description': _descriptionController.text.trim(),
          'image_path': finalImageUrl,
        },
      );

      if (response.statusCode == 200) {
        if (previousImageUrl.isNotEmpty && previousImageUrl != finalImageUrl) {
          await ApiService.deletePropertyAssetByUrl(previousImageUrl);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property specifications updated!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: VizareColors.emeraldGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Server error: ${response.body}");
      }
    } catch (e) {
      _logger.e("Update error", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update property: $e',
                style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: VisionGlassPill(
              padding: const EdgeInsets.all(8),
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          title: Text(
            'Edit Estate Listing',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Specifications',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Refine property details, pricing tiers, and architectural photography.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: VizareColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildImagePreview(),
                const SizedBox(height: 24),
                VisionGlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Listing Title'),
                      _buildInput(
                        controller: _titleController,
                        hintText: 'Listing Title',
                        icon: Icons.home_work_rounded,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Listing Price'),
                      _buildInput(
                        controller: _priceController,
                        hintText: 'e.g. RM 4,850,000',
                        icon: Icons.payments_rounded,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Location / Vicinity'),
                      _buildInput(
                        controller: _locationController,
                        hintText: 'Location',
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Architectural Description'),
                      _buildInput(
                        controller: _descriptionController,
                        hintText: 'Description',
                        icon: Icons.notes_rounded,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Listing Type'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCheckbox('For Sale', _isForSale, (v) {
                              setState(() {
                                _isForSale = v ?? false;
                                if (_isForSale) _isForRent = false;
                              });
                            }),
                          ),
                          Expanded(
                            child: _buildCheckbox('For Rent', _isForRent, (v) {
                              setState(() {
                                _isForRent = v ?? false;
                                if (_isForRent) _isForSale = false;
                              });
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Tags & Keywords'),
                      _buildTagsSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                LuxuryGradientButton(
                  text: 'Save Modifications',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isUploading,
                  onPressed: _updateProperty,
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
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
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

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: VizareColors.champagneGold,
          checkColor: Colors.black,
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    ImageProvider imageProvider;
    if (_newSelectedImages.isNotEmpty) {
      final selected = _newSelectedImages.first;
      imageProvider = selected.bytes != null
          ? MemoryImage(selected.bytes!)
          : FileImage(File(selected.path!));
    } else {
      imageProvider = NetworkImage(widget.property.imagePath);
    }

    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: VizareColors.obsidianSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: VizareColors.champagneGold.withValues(alpha: 0.3),
            ),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: VizareColors.champagneGold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      color: VizareColors.champagneGold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Replace Photo",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags
              .map(
                (tag) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VizareColors.obsidianSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          VizareColors.champagneGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: GoogleFonts.inter(
                          color: VizareColors.champagneGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: VizareColors.obsidianSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _tagInputController,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Type keyword and press Enter...',
              hintStyle: GoogleFonts.inter(color: VizareColors.textMuted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        ),
      ],
    );
  }
}
