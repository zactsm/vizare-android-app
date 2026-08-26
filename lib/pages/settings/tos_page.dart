import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class TOSPage extends StatelessWidget {
  const TOSPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const VizareAppBar(
          title: 'Terms of Service',
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                child: Text(
                  'Last Updated: August 2026',
                  style: GoogleFonts.inter(
                    fontSize: 13.0,
                    color: VizareColors.champagneGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              VisionGlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('1. Acceptance of Terms'),
                    _buildSectionBody(
                        'By downloading, accessing, or utilizing Vizare, you agree to comply with and be bound by these Terms of Service.'),
                    const SizedBox(height: 18),
                    _buildSectionHeader('2. Intellectual Property & 3D Assets'),
                    _buildSectionBody(
                        'All architectural assets, 3D renderings, and proprietary UI shaders displayed on Vizare are protected by intellectual property laws. Unauthorized reproduction or reverse-engineering is strictly prohibited.'),
                    const SizedBox(height: 18),
                    _buildSectionHeader('3. Listing Accuracy & Moderation'),
                    _buildSectionBody(
                        'Homeowners and architectural agents represent and warrant that uploaded property details and pricing are truthful, accurate, and approved under local licensing standards.'),
                    const SizedBox(height: 18),
                    _buildSectionHeader('4. Limitation of Liability'),
                    _buildSectionBody(
                        'Vizare serves as an immersive visualization exploration platform. Real-estate transactions and legal conveyancing are finalized directly between buyers and verified property representatives.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: VizareColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}
