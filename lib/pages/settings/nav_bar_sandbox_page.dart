import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/floating_bottom_nav_bar.dart';

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
    final values = '''
Nav Bar Tuned Configuration:
----------------------------------------
Container Height:    ${_config.height.toStringAsFixed(1)} px
Container Width:     ${_config.barWidth.toStringAsFixed(1)} px
Top/Bottom Padding:  ${_config.pillInsetV.toStringAsFixed(1)} px
Left/Right Inset:    ${_config.pillInsetH.toStringAsFixed(1)} px
Pill Inner Padding:  ${_config.ovalPaddingH.toStringAsFixed(1)} px
Icon-to-Text Gap:    ${_config.gapWidth.toStringAsFixed(1)} px
Inactive Item Width: ${_config.collapsedWidth.toStringAsFixed(1)} px
Bottom Elevation:    ${_config.bottomMargin.toStringAsFixed(1)} px
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
            Text(
              'Tuned values copied to clipboard!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
              value: value,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VizareColors.obsidianBlack,
      body: AbstractBackground(
        child: SafeArea(
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
                        color: VizareColors.obsidianSurface.withValues(alpha: 0.7),
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
                                Text(
                                  'Nav Bar Sandbox',
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
                top: 70,
                bottom: 120, // leave space for the preview bar
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    // Action Buttons
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
                      max: 390.0,
                      divisions: 130,
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

                    _buildSliderRow(
                      label: 'Bottom Elevation Margin',
                      value: _config.bottomMargin,
                      min: 0.0,
                      max: 50.0,
                      divisions: 50,
                      unit: 'px',
                      onChanged: (val) => setState(() => _config = _config.copyWith(bottomMargin: val)),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Live Interactive Nav Bar Preview pinned at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingBottomNavBar(
                  activeIndex: _previewIndex,
                  customConfig: _config,
                  onTap: (index) {
                    setState(() {
                      _previewIndex = index;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
