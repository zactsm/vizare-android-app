import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

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
    const backgroundColor = Color(0xFF121212);
    const double barHeight = 45.0; // Slightly smaller for a cleaner top bar look

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 1. Back Button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        // 2. The Glassy Bar is now the Title!
        centerTitle: true,
        title: Container(
          height: barHeight,
          // Limit width so it doesn't hit the back button on small screens
          constraints: const BoxConstraints(maxWidth: 270),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: (0.2)),
                Colors.white.withValues(alpha: (0.1)),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: (0.3)),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: (0.2)),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Wrap content so it's not too wide
            children: [
              Image.asset(
                'assets/images/white_home_icon.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 10),
              Flexible( // Allows text to shrink if name is very long
                child: Text(
                  widget.propertyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // 3. The Model Viewer (Takes up full screen behind the AppBar)
          ModelViewer(
            backgroundColor: Colors.transparent,
            src: widget.modelUrl,
            alt: "A 3D model of ${widget.propertyName}",
            ar: true,
            arModes: const ['scene-viewer', 'webxr', 'quick-look'],
            autoRotate: true,
            cameraControls: true,
            disableZoom: false,
          ),

          // Note: The AR button will appear automatically at the bottom-right
        ],
      ),
    );
  }
}