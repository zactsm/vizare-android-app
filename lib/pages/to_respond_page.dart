import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';
import 'package:url_launcher/url_launcher.dart';

class ToRespondPage extends StatefulWidget {
  const ToRespondPage({super.key});

  @override
  State<ToRespondPage> createState() => _ToRespondPageState();
}

class _ToRespondPageState extends State<ToRespondPage> {
  List<Map<String, dynamic>> _inquiries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
  }

  Future<void> _fetchInquiries() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.get('get_inquiries.php');
      if (response.statusCode != 200) {
        throw Exception('Could not load inquiries: ${response.body}');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _inquiries = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: VisionGlassCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                size: 38,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
          title: Text(
            'Inquiry Terminal',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: VizareColors.champagneGold,
                  ),
                )
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(color: VizareColors.crimsonRed),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _buildInquiryList(),
        ),
      ),
    );
  }

  Widget _buildInquiryList() {
    if (_inquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 56,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              'No Inquiries Pending Response',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New prospective homebuyer inquiries will arrive here.',
              style: GoogleFonts.inter(
                color: VizareColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInquiries,
      color: VizareColors.champagneGold,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _inquiries.length,
        itemBuilder: (context, index) {
          final data = _inquiries[index];
          String timeString = '';
          if (data['created_at'] != null) {
            try {
              final DateTime dt = DateTime.parse(data['created_at']);
              timeString = DateFormat('MMM d, h:mm a').format(dt.toLocal());
            } catch (_) {}
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: VisionGlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['property_name'] ?? 'Architectural Listing',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: GoogleFonts.inter(
                            color: VizareColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email_rounded,
                        color: VizareColors.champagneGold,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data['buyer_email'] ?? '',
                          style: GoogleFonts.inter(
                            color: VizareColors.champagneGold,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['message'] ?? '',
                    style: GoogleFonts.inter(
                      color: VizareColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showInquiryDetails(context, data),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: VizareColors.champagneGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: VizareColors.champagneGold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.reply_rounded,
                            color: VizareColors.champagneGold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Respond to Buyer',
                            style: GoogleFonts.inter(
                              color: VizareColors.champagneGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInquiryDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VizareColors.obsidianSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['property_name'] ?? 'Listing Inquiry',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'From Buyer:',
                style: GoogleFonts.inter(
                  color: VizareColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                data['buyer_email'] ?? '',
                style: GoogleFonts.inter(
                  color: VizareColors.champagneGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Message:',
                style: GoogleFonts.inter(
                  color: VizareColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  data['message'] ?? '',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LuxuryGradientButton(
                text: 'Launch Email Response',
                icon: Icons.send_rounded,
                onPressed: () async {
                  final String recipient = data['buyer_email'] ?? '';
                  final String subject =
                      'Re: Inquiry about ${data['property_name']}';
                  final String body =
                      '\n\n\n--- Original Inquiry ---\nFrom: $recipient\n${data['message']}';

                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: recipient,
                    query: _encodeQueryParameters(<String, String>{
                      'subject': subject,
                      'body': body,
                    }),
                  );

                  try {
                    await launchUrl(emailLaunchUri);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Could not open default email app.",
                              style: GoogleFonts.inter()),
                          backgroundColor: VizareColors.crimsonRed,
                        ),
                      );
                    }
                  }

                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
