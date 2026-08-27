import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _logger = Logger();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagInputController = TextEditingController();

  final List<PlatformFile> _selectedImages = [];
  PlatformFile? _selectedModel;
  final List<String> _tags = ['luxury', 'spatial-3d', 'penthouse'];

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

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;

      if (result.files.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(result.files);
        });
      }
    } catch (e) {
      _logger.e("Error picking images", error: e);
    }
  }

  Future<void> _pickModel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['glb', 'gltf'],
        withData: true,
      );
      final file = result?.files.single;
      if (!mounted || file == null) return;

      final lowerName = file.name.toLowerCase();
      if (lowerName.endsWith('.glb') || lowerName.endsWith('.gltf')) {
        setState(() {
          _selectedModel = file;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please select a valid .glb or .gltf 3D asset.",
                style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } catch (e) {
      _logger.e("Error picking model", error: e);
    }
  }

  Future<String?> _uploadToSupabase(PlatformFile file) =>
      ApiService.uploadPropertyAsset(file);

  Future<void> _submitProperty() async {
    if (_titleController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide at least Title and Price.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least 1 property photograph.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String? mainImageUrl = await _uploadToSupabase(_selectedImages.first);

      String? modelUrl;
      if (_selectedModel != null) {
        modelUrl = await _uploadToSupabase(_selectedModel!);
      }

      final List<String> additionalImageUrls = [];
      if (_selectedImages.length > 1) {
        for (int i = 1; i < _selectedImages.length; i++) {
          final url = await _uploadToSupabase(_selectedImages[i]);
          if (url != null) additionalImageUrls.add(url);
        }
      }

       final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null) throw Exception("User session missing.");

      final rawPrice = _priceController.text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanPrice = (double.tryParse(rawPrice) ?? 0.0).toString();

      final response = await ApiService.post(
        'add_property.php',
        body: {
          'email': email,
          'name': _titleController.text.trim(),
          'price': cleanPrice,
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'image_path': mainImageUrl ?? '',
          'model_path': modelUrl ?? '',
          'tags': jsonEncode(_tags),
          'is_for_rent': _isForRent.toString(),
          'is_for_sale': _isForSale.toString(),
          'additional_images': jsonEncode(additionalImageUrls),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Property submitted for administrative curation!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: VizareColors.emeraldGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Server response: ${response.body}");
      }
    } catch (e) {
      _logger.e("Submission error", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit listing: $e',
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
          leading: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: VisionGlassCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                size: 38,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
          title: null,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Property',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload architectural assets, imagery, and interactive 3D spatial models.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: VizareColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Photography Section
                _buildLabel('Property Photography (Primary & Gallery)'),
                _buildImageGallery(),
                const SizedBox(height: 20),
                // 3D Model Asset Section
                _buildLabel('Spatial 3D Model (.GLB / .GLTF)'),
                _buildModelPicker(),
                const SizedBox(height: 24),
                // Property Specs Form
                VisionGlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Listing Title'),
                      _buildInput(
                        controller: _titleController,
                        hintText: 'e.g. The Luminary Sky Penthouse',
                        icon: Icons.home_work_rounded,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Listing Price'),
                      _buildInput(
                        controller: _priceController,
                        hintText: '4,850,000',
                        icon: Icons.payments_rounded,
                        prefixText: 'RM ',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Location / Vicinity'),
                      _buildInput(
                        controller: _locationController,
                        hintText: 'e.g. Mont Kiara, Kuala Lumpur',
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Architectural Description'),
                      _buildInput(
                        controller: _descriptionController,
                        hintText:
                            'Describe panoramic vistas, interior finishes, smart amenities...',
                        icon: Icons.notes_rounded,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Listing Type'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCheckbox('For Sale', _isForSale, (v) {
                              setState(() => _isForSale = v ?? false);
                            }),
                          ),
                          Expanded(
                            child: _buildCheckbox('For Rent', _isForRent, (v) {
                              setState(() => _isForRent = v ?? false);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Tags & Highlights'),
                      _buildTagsSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                LuxuryGradientButton(
                  text: 'Submit Property Listing',
                  icon: Icons.cloud_upload_rounded,
                  isLoading: _isUploading,
                  onPressed: _submitProperty,
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
    String? prefixText,
    TextInputType? keyboardType,
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
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: VizareColors.champagneGold.withValues(alpha: 0.7),
            size: 20,
          ),
          prefixText: prefixText,
          prefixStyle: GoogleFonts.poppins(
            color: VizareColors.champagneGold,
            fontSize: 14,
            fontWeight: FontWeight.w700,
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

  Widget _buildImageGallery() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: VizareColors.obsidianSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: VizareColors.champagneGold.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_rounded,
                size: 36,
                color: VizareColors.champagneGold,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload High-Resolution Photographs',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: VizareColors.obsidianSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                );
              }

              final file = _selectedImages[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: file.bytes != null
                        ? Image.memory(
                            file.bytes!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(file.path!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedImages.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModelPicker() {
    return GestureDetector(
      onTap: _pickModel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: VizareColors.obsidianSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedModel != null
                ? VizareColors.emeraldGreen.withValues(alpha: 0.5)
                : VizareColors.champagneGold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedModel != null
                  ? Icons.view_in_ar_rounded
                  : Icons.upload_file_rounded,
              color: _selectedModel != null
                  ? VizareColors.emeraldGreen
                  : VizareColors.champagneGold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedModel != null
                    ? _selectedModel!.name
                    : 'Select .GLB / .GLTF 3D Architectural Model',
                style: GoogleFonts.inter(
                  color: _selectedModel != null ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedModel != null)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white60, size: 18),
                onPressed: () => setState(() => _selectedModel = null),
              ),
          ],
        ),
      ),
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
