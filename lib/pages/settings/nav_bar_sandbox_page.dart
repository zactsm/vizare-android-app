import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/floating_bottom_nav_bar.dart';

enum PreviewBgMode { brightSlate, propertyCard, darkTheme }

class NavBarSandboxPage extends StatefulWidget {
  const NavBarSandboxPage({super.key});

  @override
  State<NavBarSandboxPage> createState() => _NavBarSandboxPageState();
}

class _NavBarSandboxPageState extends State<NavBarSandboxPage> {
  // Baseline / default values
  static const NavBarConfig _defaultConfig = NavBarConfig(
    height: 70.0,
    barWidth: 330.0,
    pillInsetH: 5.0,
    pillInsetV: 6.0,
    ovalPaddingH: 11.0,
    gapWidth: 6.0,
    collapsedWidth: 36.0,
    bottomMargin: 24.0,
  );

  late NavBarConfig _config;
  NavPageIndex _previewIndex = NavPageIndex.home;
  PreviewBgMode _bgMode = PreviewBgMode.brightSlate;

  @override
  void initState() {
    super.initState();
    _config = _defaultConfig;
  }

  void _resetToDefaults() {
    setState(() {
      _config = _defaultConfig;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to default values'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _copyValuesToClipboard() {
    final platformName = kIsWeb
        ? 'Web (Vercel)'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android');

    final values = '''
Nav Bar Configuration ($platformName):
----------------------------------------
Container Height:    ${_config.height.toStringAsFixed(1)} px
Container Width:     ${_config.barWidth.toStringAsFixed(1)} px
Top/Bottom Padding:  ${_config.pillInsetV.toStringAsFixed(1)} px
Left/Right Inset:    ${_config.pillInsetH.toStringAsFixed(1)} px
Pill Inner Padding:  ${_config.ovalPaddingH.toStringAsFixed(1)} px
Icon-to-Text Gap:    ${_config.gapWidth.toStringAsFixed(1)} px
Inactive Item Width: ${_config.collapsedWidth.toStringAsFixed(1)} px
Bottom Margin:       ${_config.bottomMargin.toStringAsFixed(1)} px
----------------------------------------
Dart Code:
NavBarConfig(
  height: ${_config.height.toStringAsFixed(1)},
  barWidth: ${_config.barWidth.toStringAsFixed(1)},
  pillInsetV: ${_config.pillInsetV.toStringAsFixed(1)},
  pillInsetH: ${_config.pillInsetH.toStringAsFixed(1)},
  ovalPaddingH: ${_config.ovalPaddingH.toStringAsFixed(1)},
  gapWidth: ${_config.gapWidth.toStringAsFixed(1)},
  collapsedWidth: ${_config.collapsedWidth.toStringAsFixed(1)},
  bottomMargin: ${_config.bottomMargin.toStringAsFixed(1)},
)''';

    Clipboard.setData(ClipboardData(text: values));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: VizareColors.goldDark,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Values for $platformName copied to clipboard!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VizareColors.obsidianSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: VizareColors.champagneGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: VizareColors.champagneGold.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: VizareColors.champagneGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: VizareColors.champagneGold,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: VizareColors.champagneGold,
              overlayColor: VizareColors.champagneGold.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBackdrop() {
    switch (_bgMode) {
      case PreviewBgMode.brightSlate:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2C3E50),
                Color(0xFF4A6572),
                Color(0xFF78909C),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Grid lines for visual precision
              CustomPaint(
                painter: _GridPainter(),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '📱 Screen Bottom Edge',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case PreviewBgMode.propertyCard:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A365D),
                Color(0xFF0F766E),
                Color(0xFF065F46),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VizareColors.champagneGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skyline Penthouse • RM 2,450,000',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Kuala Lumpur City Centre • 4 Beds 3 Baths',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        );

      case PreviewBgMode.darkTheme:
        return Container(
          color: VizareColors.obsidianBlack,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformName = kIsWeb
        ? 'Web (Vercel)'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android');

    return Scaffold(
      backgroundColor: VizareColors.obsidianBlack,
      body: AbstractBackground(
        child: SafeArea(
          bottom: false, // Allows full reach to the true physical bottom of screen
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: VizareColors.obsidianSurface.withValues(alpha: 0.85),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Nav Bar Sandbox',
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: VizareColors.champagneGold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: VizareColors.champagneGold.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        platformName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: VizareColors.champagneGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Tune values live & copy report',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: VizareColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: VizareColors.champagneGold),
                            tooltip: 'Reset to defaults',
                            onPressed: _resetToDefaults,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable Sliders List
              Positioned.fill(
                top: 75,
                bottom: 155, // leaves space for the preview bar
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Background Contrast Selector
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VizareColors.obsidianSurface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview Backdrop Contrast:',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: VizareColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBgOptionButton(
                                  label: 'Bright Slate',
                                  icon: Icons.contrast_rounded,
                                  mode: PreviewBgMode.brightSlate,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBgOptionButton(
                                  label: 'Property Card',
                                  icon: Icons.image_outlined,
                                  mode: PreviewBgMode.propertyCard,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBgOptionButton(
                                  label: 'Dark Obsidian',
                                  icon: Icons.dark_mode_rounded,
                                  mode: PreviewBgMode.darkTheme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons (Copy & Reset)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VizareColors.champagneGold,
                              foregroundColor: VizareColors.obsidianBlack,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(
                              'Copy Values',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: _copyValuesToClipboard,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: Text(
                            'Reset',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _resetToDefaults,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSliderRow(
                      label: 'Bottom Elevation Margin',
                      value: _config.bottomMargin,
                      min: 0.0,
                      max: 60.0,
                      divisions: 60,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(bottomMargin: val)),
                    ),

                    _buildSliderRow(
                      label: 'Container Height',
                      value: _config.height,
                      min: 50.0,
                      max: 90.0,
                      divisions: 40,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(height: val)),
                    ),

                    _buildSliderRow(
                      label: 'Container Width',
                      value: _config.barWidth,
                      min: 260.0,
                      max: 400.0,
                      divisions: 140,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(barWidth: val)),
                    ),

                    _buildSliderRow(
                      label: 'Top & Bottom Padding (pillInsetV)',
                      value: _config.pillInsetV,
                      min: 0.0,
                      max: 16.0,
                      divisions: 32,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(pillInsetV: val)),
                    ),

                    _buildSliderRow(
                      label: 'Left & Right Inset (pillInsetH)',
                      value: _config.pillInsetH,
                      min: 0.0,
                      max: 20.0,
                      divisions: 40,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(pillInsetH: val)),
                    ),

                    _buildSliderRow(
                      label: 'Pill Inner Padding (ovalPaddingH)',
                      value: _config.ovalPaddingH,
                      min: 4.0,
                      max: 24.0,
                      divisions: 40,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(ovalPaddingH: val)),
                    ),

                    _buildSliderRow(
                      label: 'Icon-to-Text Gap (gapWidth)',
                      value: _config.gapWidth,
                      min: 2.0,
                      max: 16.0,
                      divisions: 28,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(gapWidth: val)),
                    ),

                    _buildSliderRow(
                      label: 'Inactive Item Width (collapsedWidth)',
                      value: _config.collapsedWidth,
                      min: 24.0,
                      max: 56.0,
                      divisions: 32,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(collapsedWidth: val)),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Bottom Preview Dock Area with High-Contrast Backdrop
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Dynamic backdrop behind the floating nav bar
                    _buildPreviewBackdrop(),

                    // Subtle top border dividing controls from preview dock
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),

                    // Live Interactive Nav Bar Preview
                    FloatingBottomNavBar(
                      activeIndex: _previewIndex,
                      customConfig: _config,
                      onTap: (index) {
                        setState(() {
                          _previewIndex = index;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBgOptionButton({
    required String label,
    required IconData icon,
    required PreviewBgMode mode,
  }) {
    final isSelected = _bgMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _bgMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? VizareColors.champagneGold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? VizareColors.champagneGold
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? VizareColors.champagneGold : Colors.white60,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? VizareColors.champagneGold : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
