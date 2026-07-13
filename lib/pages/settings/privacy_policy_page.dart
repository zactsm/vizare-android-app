import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Make status bar icons light
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ListView(
          children: const [
            SizedBox(height: 8),
            Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Effective Date: 1 May 2025',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8), // space between title and paragraph
            Text(
              'Your privacy is important to us. This policy explains how VIZARE collects, uses, and protects your data.',
              style: TextStyle(
                color: Colors.white70, // slightly dimmed white
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            _FAQItem(
              question: '1. Information We Collect',
              answer:
              'Personal details (e.g., name, email address, phone number), User role, property data, and device information for AR functionality.',
            ),
            _FAQItem(
              question: '2. How We Use Your Data',
              answer:
              'To provide and improve our services, to personalize your app experience, and to contact you with updates or support.',
            ),
            _FAQItem(
              question: '3. Data Sharing',
              answer:
              'We do not sell your data. We may share information with trusted service providers for functionality (e.g., AR rendering or cloud storage) under strict confidentiality agreements.',
            ),
            _FAQItem(
              question: '4. Data Security',
              answer:
              'We use industry-standard encryption and secure servers to protect your information.',
            ),
            _FAQItem(
              question: '5. Cookies and Tracking',
              answer:
              'We may use basic analytics tools to understand user behavior and improve the app experience.',
            ),
            _FAQItem(
              question: '6. Your Rights',
              answer:
              'You may request access to or deletion of your personal data by contacting us at vizare@support.com.',
            ),
            _FAQItem(
              question: '7. Changes to this Policy',
              answer:
              'We may update this policy periodically. Continued use of the app implies acceptance of the revised terms.',
            ),
          ],
        ),
      ),
    );
  }
}

// Custom FAQ item widget
class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: (0.7)),
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
