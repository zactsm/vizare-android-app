import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
            title: 'Privacy Policy',
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                  child: Text(
                    'Effective Date: August 2026',
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
                      _buildSectionHeader('1. Data Controller & Scope', isDark),
                      _buildSectionBody(
                          'Vizare Technologies Inc. acts as the Data Controller under EU GDPR and Business entity under California CCPA/CPRA. This policy governs how we process personal information across our mobile and web applications.',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('2. Information Collection & Legal Bases', isDark),
                      _buildSectionBody(
                          'Under GDPR Art. 6, we process account credentials (full name, email, encrypted password), phone numbers, inquiry records, and interaction telemetry based on contractual necessity (Art. 6(1)(b)) and legitimate interest in platform security (Art. 6(1)(f)).',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('3. Spatial, AR & Camera Privacy', isDark),
                      _buildSectionBody(
                          'AR camera feeds, LiDAR, and gyro sensors operate exclusively on-device for real-time WebGL/glTF model rendering. Raw camera frames and spatial room meshes are never recorded, persisted, or transmitted to remote servers.',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('4. Sub-Processors & Data Transfers', isDark),
                      _buildSectionBody(
                          'We utilize vetted third-party service providers bound by Data Processing Agreements (DPAs):\n• Supabase Inc. (Database, Authentication, Storage - AWS us-east)\n• Google LLC (Google Maps API, Google Sign-In)\n• EmailJS (Support ticket relay)',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('5. Your Rights (GDPR & CCPA/CPRA)', isDark),
                      _buildSectionBody(
                          'You have enforceable rights regarding your personal information:\n• Right of Access & Portability (Art. 15/20 GDPR): Download machine-readable JSON data via Account Settings.\n• Right to Erasure (Art. 17 GDPR, CCPA § 1798.105): Permanently purge your profile, auth credentials, and uploaded files.\n• CCPA Notice: We DO NOT sell or share your personal data with third-party data brokers for cross-context behavioral advertising.',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('6. Data Retention & Erasure', isDark),
                      _buildSectionBody(
                          'Account and listing data are retained while your account is active. When you execute an Account Erasure request, all personally identifiable records and storage files are immediately deleted or irrevocably anonymized.',
                          isDark),
                      const SizedBox(height: 18),
                      _buildSectionHeader('7. Data Protection Contact', isDark),
                      _buildSectionBody(
                          'To exercise your statutory data subject rights or reach our Data Protection Officer (DPO), submit a request via Settings > Contact Support or email privacy@vizare.app.',
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
