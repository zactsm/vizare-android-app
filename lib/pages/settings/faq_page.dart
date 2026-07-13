import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Make status bar icons light
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
              'Frequently Asked Questions (FAQs)',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24),
            _FAQItem(
              question: '1. What is VIZARE?',
              answer:
              'VIZARE is a mobile application that allows users to explore real estate properties in augmented reality. Homebuyers can view property listings, explore them virtually, and contact property owners or agents directly.',
            ),
            _FAQItem(
              question: '2. Who can use this app?',
              answer:
              'Anyone interested in buying, selling, or exploring real estate can use the app. Users can register as either a Homebuyer or a Homeowner during sign-up.',
            ),
            _FAQItem(
              question: '3. How do I view a property in AR?',
              answer:
              'Once you\'ve selected a property from the listing, tap on the “View in AR” button. Make sure your device supports AR and has the necessary permissions enabled (camera and motion sensors).',
            ),
            _FAQItem(
              question: '4. How do I add my property?',
              answer:
              'If you\'re a homeowner, you can use the “Add Property” feature in your dashboard to upload property details, images, and AR-compatible 3D models.',
            ),
            _FAQItem(
              question: '5. Is it free to use?',
              answer:
              'Yes, VIZARE is free to download and use. Some premium features for homeowners may be introduced in future versions.',
            ),
            _FAQItem(
              question: '6. What devices are supported?',
              answer:
              'AR features are supported on most modern Android and iOS devices that include ARKit or ARCore compatibility.',
            ),
            _FAQItem(
              question: '7. How is my data protected?',
              answer:
              'Your personal data is protected in accordance with our Privacy Policy. We never sell your data to third parties.',
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Custom FAQ item widget
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
