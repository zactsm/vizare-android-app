import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'utils/app_theme.dart';

class ArViewPage extends StatefulWidget {
  final String modelUrl;
  final String propertyName;

  const ArViewPage({
    super.key,
    required this.modelUrl,
    required this.propertyName,
  });

  @override
  State<ArViewPage> createState() => _ArViewPageState();
}

class _ArViewPageState extends State<ArViewPage> {
  bool _autoRotate = true;
  int _lightingIndex = 0; // 0 = Golden Hour, 1 = Studio Daylight, 2 = Cyber Twilight

  final List<Map<String, dynamic>> _lightingModes = [
    {
      'label': 'Golden Sun',
      'icon': Icons.wb_sunny_rounded,
      'color': VizareColors.champagneGold,
      'exposure': '1.1',
      // shadowIntensity capped at 1.0 — model_viewer_plus throws RangeError if > 1
      'shadowIntensity': '1.0',
    },
    {
      'label': 'Studio Light',
      'icon': Icons.light_mode_rounded,
      'color': VizareColors.goldLight,
      'exposure': '1.0',
      'shadowIntensity': '0.9',
    },
    {
      'label': 'Twilight Glow',
      'icon': Icons.nightlight_round,
      'color': VizareColors.spatialCyan,
      'exposure': '0.8',
      // capped at 1.0 — values > 1.0 are clamped by model_viewer_plus
      'shadowIntensity': '1.0',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentLight = _lightingModes[_lightingIndex];

    return Scaffold(
      backgroundColor: VizareColors.obsidianBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: VisionGlassCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
        centerTitle: true,
        title: VisionGlassContainer(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          borderRadius: 24,
          backgroundColor: VizareColors.obsidianSurface.withValues(alpha: 0.75),
          border: Border.all(
            color: VizareColors.champagneGold.withValues(alpha: 0.4),
            width: 1.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.view_in_ar_rounded,
                color: VizareColors.champagneGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.propertyName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Ambient Sun / Twilight Radiant Glow in Canvas
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (currentLight['color'] as Color).withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Full-bleed 3D Model Canvas
          Positioned.fill(
            child: ModelViewer(
              // Key on modelUrl so switching lighting doesn't rebuild the WebView
              key: ValueKey(widget.modelUrl.isNotEmpty
                  ? widget.modelUrl
                  : 'default-model'),
              backgroundColor: Colors.transparent,
              src: widget.modelUrl.isNotEmpty
                  ? widget.modelUrl
                  : 'https://ttuxazxgkgrpakdedngw.supabase.co/storage/v1/object/public/property-assets/3d_models/GlamVelvetSofa.glb',
              alt: '3D architectural model of ${widget.propertyName}',
              ar: true,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: _autoRotate,
              cameraControls: true,
              disableZoom: false,
              loading: Loading.eager,
              exposure: double.tryParse(currentLight['exposure']) ?? 1.0,
              // NOTE: shadowIntensity is intentionally omitted here.
              // The model_viewer_plus library (v1.9.3) has two bugs with this parameter:
              //   1. It throws a RangeError for values > 1.0 (even though model-viewer
              //      itself accepts values > 1)
              //   2. It appends a stray '}' inside the HTML attribute value when the
              //      parameter is set, producing shadow-intensity="1.0}" which is
              //      malformed HTML.
              // We instead set shadow intensity via relatedJs after the model loads.
              relatedJs: '''
                window.addEventListener('load', function() {
                  const mv = document.querySelector('model-viewer');
                  if (mv) mv.setAttribute('shadow-intensity', '${currentLight['shadowIntensity']}');
                });
              ''',
            ),
          ),

          // 3. VisionOS Floating Spatial HUD Controls (Bottom-Left)
          Positioned(
            bottom: 30,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lighting Switcher Pill
                VisionGlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 22,
                  backgroundColor:
                      VizareColors.obsidianSurface.withValues(alpha: 0.85),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  onTap: () {
                    setState(() {
                      _lightingIndex =
                          (_lightingIndex + 1) % _lightingModes.length;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentLight['icon'] as IconData,
                        color: currentLight['color'] as Color,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentLight['label'] as String,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Auto-Rotation Toggle Pill
                VisionGlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 22,
                  backgroundColor:
                      VizareColors.obsidianSurface.withValues(alpha: 0.85),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  onTap: () {
                    setState(() {
                      _autoRotate = !_autoRotate;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoRotate
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: _autoRotate
                            ? VizareColors.spatialCyan
                            : VizareColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _autoRotate ? 'Orbit: ON' : 'Orbit: OFF',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
