import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const VizareAppBar(
          title: 'Privacy Policy',
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Text(
                'Data & Privacy Governance',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Effective Date: August 2026',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: VizareColors.champagneGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              VisionGlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('1. Information Collection'),
                    _buildSectionBody(
                        'We collect account profile credentials, architectural preference tags, and spatial telemetry to provide high-fidelity 3D and AR visualization services.'),
                    const SizedBox(height: 18),
                    _buildSectionHeader('2. Spatial & Sensor Data'),
                    _buildSectionBody(
                        'AR camera and gyro sensors operate locally on-device to project 3D models into your physical environment. Raw camera feeds are never stored or transmitted to external servers.'),
                    const SizedBox(height: 18),
                    _buildSectionHeader('3. Security & Row-Level Protection'),
                    _buildSectionBody(
                        'Personal data, saved bookmarks, and inquiry communications are safeguarded by cryptographic Row-Level Security (RLS) policies and HTTPS encrypted tunnels.'),
                    const SizedBox(height: 18),
                    _buildSectionHeader('4. Contact & Compliance'),
                    _buildSectionBody(
                        'For data deletion requests or privacy inquiries, contact our data protection officer via the Concierge Support page.'),
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
