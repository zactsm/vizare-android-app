import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TOSPage extends StatelessWidget {
  const TOSPage({super.key});

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
              'Terms of Service',
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
              'Welcome to VIZARE! By using our app, you agree to the following terms:',
              style: TextStyle(
                color: Colors.white70, // slightly dimmed white
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            _FAQItem(
              question: '1. Eligibility',
              answer:
              'You must be at least 18 years old to use VIZARE. By signing up, you confirm that the information provided is accurate and truthful.',
            ),
            _FAQItem(
              question: '2. User Accounts',
              answer:
              'Users are responsible for maintaining the confidentiality of their account credentials. You are responsible for all activities that occur under your account.',
            ),
            _FAQItem(
              question: '3. Acceptable Use',
              answer:
              'You agree not to use the app for any illegal, fraudulent, or harmful purpose. You must not attempt to hack, disrupt, or misuse any part of the system.',
            ),
            _FAQItem(
              question: '4. Property Listings',
              answer:
              'Homeowners are solely responsible for the accuracy of the property information submitted. VIZARE reserves the right to review or remove listings that violate our guidelines.',
            ),
            _FAQItem(
              question: '5. Intellectual Property',
              answer:
              'All app content, branding, and code are owned by VIZARE. You may not copy, modify, or distribute content without written permission.',
            ),
            _FAQItem(
              question: '6. Termination',
              answer:
              'We may suspend or terminate your account if you violate these terms.',
            ),
            _FAQItem(
              question: '7. Modifications',
              answer:
              'We reserve the right to update or modify these Terms at any time. Changes will be posted in the app and become effective upon posting.',
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
