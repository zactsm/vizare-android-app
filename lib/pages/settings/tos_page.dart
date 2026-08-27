import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class TOSPage extends StatelessWidget {
  const TOSPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
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
                      _buildSectionHeader('1. Acceptance of Terms', isDark),
                      _buildSectionBody(
                          'By downloading, accessing, or utilizing Vizare, you agree to comply with and be bound by these Terms of Service.',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('2. Intellectual Property & 3D Assets', isDark),
                      _buildSectionBody(
                          'All architectural assets, 3D renderings, and proprietary UI shaders displayed on Vizare are protected by intellectual property laws. Unauthorized reproduction or reverse-engineering is strictly prohibited.',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('3. Listing Accuracy & Moderation', isDark),
                      _buildSectionBody(
                          'Homeowners and architectural agents represent and warrant that uploaded property details and pricing are truthful, accurate, and approved under local licensing standards.',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('4. Limitation of Liability', isDark),
                      _buildSectionBody(
                          'Vizare serves as an immersive visualization exploration platform. Real-estate transactions and legal conveyancing are finalized directly between buyers and verified property representatives.',
                          isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildSectionBody(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
          height: 1.5,
        ),
      ),
    );
  }
}
