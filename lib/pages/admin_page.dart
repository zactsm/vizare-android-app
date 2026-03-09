import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/models/property_model.dart'; // Make sure this import is correct

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Property> _pendingProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingProperties();
  }

  Future<void> _fetchPendingProperties() async {

    final url = 'https://formidable-fort-475806-q1.et.r.appspot.com/get_pending_properties.php';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _pendingProperties = data.map((json) => Property.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching pending: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int propertyId, String newStatus) async {
    // Optimistic UI update: Remove from list immediately
    setState(() {
      _pendingProperties.removeWhere((p) => p.id == propertyId);
    });

    final url = 'https://formidable-fort-475806-q1.et.r.appspot.com/update_property_status.php';

    try {
      await http.post(
        Uri.parse(url),
        body: {
          'property_id': propertyId.toString(),
          'status': newStatus,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property $newStatus!'),
          backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
      _fetchPendingProperties(); // Revert if failed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Black background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGradientTitle("Admin\nMenu"),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  )
                ],
              ),
              const SizedBox(height: 30),

              // 2. The List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                    : _pendingProperties.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  itemCount: _pendingProperties.length,
                  itemBuilder: (context, index) {
                    return _buildAdminCard(_pendingProperties[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.white.withValues(alpha: (0.2))),
          const SizedBox(height: 16),
          Text(
            "All caught up!\nNo pending listings.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: (0.5)), fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0), // Light grey card background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: (0.1))),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.black12,
                  child: Image.network(
                    property.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Right: Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property.price,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons (Row at bottom right)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Reject Button (Grey X)
              GestureDetector(
                onTap: () => _updateStatus(property.id, 'rejected'),
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),

              // Approve Button (Cyan Check)
              GestureDetector(
                onTap: () => _updateStatus(property.id, 'approved'),
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.cyan[400], // Matches your design gradient
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientTitle(String text) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.yellowAccent, Colors.cyanAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 32,
          height: 1.0,
          fontWeight: FontWeight.w900,
          fontFamily: 'Poppins',
          color: Colors.white,
        ),
      ),
    );
  }
}