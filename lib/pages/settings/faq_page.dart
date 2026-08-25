import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const VizareAppBar(
          title: 'FAQ',
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Text(
                'Frequently Asked Questions (FAQs)',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Discover how Vizare transforms luxury real-estate with spatial 3D and AR.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: VizareColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const _FAQItem(
                question: 'What is Vizare Spatial Real Estate?',
                answer:
                    'Vizare is a spatial property exploration platform featuring interactive 3D model viewports and augmented reality tours for luxury architectural homes.',
              ),
              const _FAQItem(
                question: 'How do I explore a home in 3D / AR?',
                answer:
                    'Tap "Explore in 3D / AR" on any verified property listing to launch the spatial HUD with real-time lighting modes (Golden Sun, Studio, Twilight) and camera orbit.',
              ),
              const _FAQItem(
                question: 'How do homeowners submit listings?',
                answer:
                    'Switch to the Homeowner terminal to upload property imagery, architectural specifications, and standard .GLB 3D assets for moderation approval.',
              ),
              const _FAQItem(
                question: 'What devices support spatial viewports?',
                answer:
                    'All modern Android, iOS, and WebGL browsers with WebXR, ARCore, or ARKit compatibility are fully supported.',
              ),
              const _FAQItem(
                question: 'How is listing data verified and secured?',
                answer:
                    'All property records enforce cryptographic row-level security (RLS) triggers, administrative moderation queues, and sanitized asset pipelines.',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: VizareColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              widget.question,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: VizareColors.champagneGold,
            ),
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  widget.answer,
                  style: GoogleFonts.inter(
                    color: VizareColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
