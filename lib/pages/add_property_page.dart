import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

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

  String _selectedPropertyType = 'Condominium';
  List<String> _availablePropertyTypes = [
    'Apartment / Flat',
    'Condominium',
    'Luxury Villa',
    'Duplex / Penthouse',
    'Detached House / Bungalow',
    'Terraced House / Townhouse',
    'Serviced Residence',
    'Loft',
    'Studio Unit',
    'Commercial Property',
    'Modern Luxury',
  ];

  bool _isForRent = false;
  bool _isForSale = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchPropertyTypes();
  }

  Future<void> _fetchPropertyTypes() async {
    try {
      final response = await ApiService.get('get_property_types.php');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && mounted) {
          setState(() {
            _availablePropertyTypes =
                data.map((item) => item['name'].toString()).toList();
            if (!_availablePropertyTypes.contains(_selectedPropertyType) &&
                _availablePropertyTypes.isNotEmpty) {
              _selectedPropertyType = _availablePropertyTypes.first;
            }
          });
        }
      }
    } catch (e) {
      _logger.w("Could not fetch remote property types, using fallback", error: e);
    }
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
          'property_type': _selectedPropertyType,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
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
                  iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload architectural assets, imagery, and interactive 3D spatial models.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? VizareColors.textSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Photography Section
                  _buildLabel('Property Photography (Primary & Gallery)'),
                  _buildImageGallery(isDark),
                  const SizedBox(height: 20),
                  // 3D Model Asset Section
                  _buildLabel('Spatial 3D Model (.GLB / .GLTF)'),
                  _buildModelPicker(isDark),
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
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Property Type'),
                        _buildPropertyTypeDropdown(isDark),
                        const SizedBox(height: 18),
                        _buildLabel('Listing Price'),
                        _buildInput(
                          controller: _priceController,
                          hintText: '4,850,000',
                          icon: Icons.payments_rounded,
                          persistentPrefixText: 'RM ',
                          keyboardType: TextInputType.number,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Location / Vicinity'),
                        _buildInput(
                          controller: _locationController,
                          hintText: 'e.g. Mont Kiara, Kuala Lumpur',
                          icon: Icons.location_on_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Architectural Description'),
                        _buildInput(
                          controller: _descriptionController,
                          hintText:
                              'Describe panoramic vistas, interior finishes, smart amenities...',
                          icon: Icons.notes_rounded,
                          maxLines: 5,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Listing Type'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCheckbox('For Sale', _isForSale, (v) {
                                setState(() => _isForSale = v ?? false);
                              }, isDark),
                            ),
                            Expanded(
                              child: _buildCheckbox('For Rent', _isForRent, (v) {
                                setState(() => _isForRent = v ?? false);
                              }, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Tags & Highlights'),
                        _buildTagsSection(isDark),
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
      ),
    );
  }

  Widget _buildPropertyTypeDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? VizareColors.obsidianSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _availablePropertyTypes.contains(_selectedPropertyType)
              ? _selectedPropertyType
              : (_availablePropertyTypes.isNotEmpty
                  ? _availablePropertyTypes.first
                  : null),
          isExpanded: true,
          dropdownColor:
              isDark ? VizareColors.obsidianElevated : Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: VizareColors.champagneGold,
          ),
          items: _availablePropertyTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  const Icon(
                    Icons.holiday_village_rounded,
                    color: VizareColors.champagneGold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    type,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedPropertyType = val);
            }
          },
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
    String? persistentPrefixText,
    TextInputType? keyboardType,
    bool isDark = true,
  }) {
    final bool isMultiLine = maxLines > 1;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? VizareColors.obsidianSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: isMultiLine
              ? Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10, top: 14),
                  child: Align(
                    alignment: Alignment.topLeft,
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: Icon(
                      icon,
                      color: VizareColors.champagneGold.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                )
              : (persistentPrefixText != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: VizareColors.champagneGold
                                .withValues(alpha: 0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            persistentPrefixText,
                            style: GoogleFonts.poppins(
                              color: VizareColors.champagneGold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      icon,
                      color: VizareColors.champagneGold.withValues(alpha: 0.7),
                      size: 20,
                    )),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
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
      String label, bool value, ValueChanged<bool?> onChanged, bool isDark) {
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
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(bool isDark) {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? VizareColors.obsidianSurface : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? VizareColors.champagneGold.withValues(alpha: 0.3)
                  : const Color(0xFFCBD5E1),
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
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
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
                      color: isDark ? VizareColors.obsidianSurface : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
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
                        : (!kIsWeb && file.path != null
                            ? Image.file(
                                File(file.path!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(width: 120, height: 120)),
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

  Widget _buildModelPicker(bool isDark) {
    return GestureDetector(
      onTap: _pickModel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? VizareColors.obsidianSurface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedModel != null
                ? VizareColors.emeraldGreen.withValues(alpha: 0.5)
                : (isDark
                    ? VizareColors.champagneGold.withValues(alpha: 0.3)
                    : const Color(0xFFCBD5E1)),
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
                  color: _selectedModel != null
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedModel != null)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  size: 18,
                ),
                onPressed: () => setState(() => _selectedModel = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(bool isDark) {
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
                    color: isDark
                        ? VizareColors.obsidianSurface
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? VizareColors.champagneGold.withValues(alpha: 0.3)
                          : const Color(0xFFCBD5E1),
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
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
            color: isDark ? VizareColors.obsidianSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
            ),
          ),
          child: TextField(
            controller: _tagInputController,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Type keyword and press Enter...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
              ),
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
