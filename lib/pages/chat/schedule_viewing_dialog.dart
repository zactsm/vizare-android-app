import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/utils/app_theme.dart';

class ScheduleViewingDialog extends StatefulWidget {
  final Property property;
  final Function(DateTime date, String timeSlot, String tourMode, String note) onSchedule;

  const ScheduleViewingDialog({
    super.key,
    required this.property,
    required this.onSchedule,
  });

  static Future<void> show({
    required BuildContext context,
    required Property property,
    required Function(DateTime date, String timeSlot, String tourMode, String note) onSchedule,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleViewingDialog(
        property: property,
        onSchedule: onSchedule,
      ),
    );
  }

  @override
  State<ScheduleViewingDialog> createState() => _ScheduleViewingDialogState();
}

class _ScheduleViewingDialogState extends State<ScheduleViewingDialog> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '2:00 PM';
  String _selectedTourMode = 'in_person'; // 'in_person' or 'virtual_ar'
  final _noteController = TextEditingController();

  final List<String> _timeSlots = [
    '10:00 AM',
    '11:30 AM',
    '2:00 PM',
    '3:30 PM',
    '5:00 PM',
    '6:30 PM',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: VizareColors.champagneGold,
              onPrimary: Colors.black,
              surface: VizareColors.obsidianSurface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: VizareColors.obsidianBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? VizareColors.obsidianSurface.withValues(alpha: 0.96)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? VizareColors.champagneGold.withValues(alpha: 0.25)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: VizareColors.champagneGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VizareColors.champagneGold.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: VizareColors.champagneGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule a Viewing',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        widget.property.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Tour Mode Selector
            Text(
              'TOUR EXPERIENCE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: VizareColors.champagneGold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    id: 'in_person',
                    title: 'On-Site Tour',
                    subtitle: 'In-person estate visit',
                    icon: Icons.location_city_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeCard(
                    id: 'virtual_ar',
                    title: 'Virtual 3D AR',
                    subtitle: 'Guided walkthrough',
                    icon: Icons.view_in_ar_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Date Selection
            Text(
              'PREFERRED DATE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: VizareColors.champagneGold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickCustomDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? VizareColors.champagneGold.withValues(alpha: 0.3)
                        : const Color(0xFFCBD5E1),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      color: VizareColors.champagneGold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Change',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: VizareColors.champagneGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Time Slot Selection
            Text(
              'PREFERRED TIME SLOT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: VizareColors.champagneGold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTimeSlot = slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VizareColors.champagneGold
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? VizareColors.champagneGold
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0)),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 4. Optional Special Requests Note
            Text(
              'SPECIAL INSTRUCTIONS (OPTIONAL)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: VizareColors.champagneGold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Would love to inspect the rooftop terrace and master suite...',
                hintStyle: GoogleFonts.inter(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: VizareColors.champagneGold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Submit CTA Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onSchedule(
                  _selectedDate,
                  _selectedTimeSlot,
                  _selectedTourMode,
                  _noteController.text.trim(),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFDF7A),
                      VizareColors.champagneGold,
                      Color(0xFFB58E2A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: VizareColors.champagneGold.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Request Exclusive Viewing',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedTourMode == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTourMode = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? VizareColors.champagneGold.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? VizareColors.champagneGold
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? VizareColors.champagneGold : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
