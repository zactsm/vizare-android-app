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

  late String _selectedPropertyType;
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
    _selectedPropertyType = widget.property.propertyType.isNotEmpty
        ? widget.property.propertyType
        : 'Condominium';
    _fetchPropertyTypes();
    _titleController = TextEditingController(text: widget.property.name);
    final initialNumeric = widget.property.numericPrice > 0
        ? (widget.property.numericPrice % 1 == 0
            ? widget.property.numericPrice.toInt().toString()
            : widget.property.numericPrice.toString())
        : widget.property.price.replaceAll(RegExp(r'[^0-9.]'), '');
    _priceController = TextEditingController(text: initialNumeric);
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _locationController =
        TextEditingController(text: widget.property.location);
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
            if (!_availablePropertyTypes.contains(_selectedPropertyType)) {
              _availablePropertyTypes.insert(0, _selectedPropertyType);
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

      final rawPrice = _priceController.text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanPrice = (double.tryParse(rawPrice) ?? 0.0).toString();

      final response = await ApiService.post(
        'edit_property.php',
        body: {
          'email': email,
          'property_id': widget.property.id.toString(),
          'name': _titleController.text.trim(),
          'property_type': _selectedPropertyType,
          'location': _locationController.text.trim(),
          'price': cleanPrice,
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
            title: Text(
              'Edit Estate Listing',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Refine property details, pricing tiers, and architectural photography.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? VizareColors.textSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildImagePreview(isDark),
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
                          hintText: 'Location',
                          icon: Icons.location_on_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Architectural Description'),
                        _buildInput(
                          controller: _descriptionController,
                          hintText: 'Description',
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
                                setState(() {
                                  _isForSale = v ?? false;
                                  if (_isForSale) _isForRent = false;
                                });
                              }, isDark),
                            ),
                            Expanded(
                              child: _buildCheckbox('For Rent', _isForRent, (v) {
                                setState(() {
                                  _isForRent = v ?? false;
                                  if (_isForRent) _isForSale = false;
                                });
                              }, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildLabel('Tags & Keywords'),
                        _buildTagsSection(isDark),
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

  Widget _buildImagePreview(bool isDark) {
    ImageProvider imageProvider;
    if (_newSelectedImages.isNotEmpty) {
      final selected = _newSelectedImages.first;
      if (selected.bytes != null) {
        imageProvider = MemoryImage(selected.bytes!);
      } else if (!kIsWeb && selected.path != null && selected.path!.isNotEmpty) {
        imageProvider = FileImage(File(selected.path!));
      } else {
        imageProvider = NetworkImage(widget.property.imagePath);
      }
    } else {
      imageProvider = NetworkImage(widget.property.imagePath);
    }

    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? VizareColors.obsidianSurface : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? VizareColors.champagneGold.withValues(alpha: 0.3)
                  : const Color(0xFFCBD5E1),
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
