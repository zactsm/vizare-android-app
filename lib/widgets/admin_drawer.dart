import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/utils/app_theme.dart';

enum AdminView {
  moderation,
  listings,
  users,
  analytics,
}

class AdminDrawer extends StatelessWidget {
  final AdminView currentView;
  final int pendingCount;
  final String? adminEmail;
  final ValueChanged<AdminView> onViewSelected;
  final VoidCallback onSignOut;

  const AdminDrawer({
    super.key,
    required this.currentView,
    required this.pendingCount,
    this.adminEmail,
    required this.onViewSelected,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.82,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: VizareColors.obsidianBlack.withValues(alpha: 0.88),
              border: Border(
                right: BorderSide(
                  color: VizareColors.champagneGold.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Admin Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: VizareColors.goldGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: VizareColors.champagneGold.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: VizareColors.obsidianBlack,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VIZARE CONSOLE',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: VizareColors.champagneGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: VizareColors.champagneGold.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'SUPER ADMIN',
                                      style: GoogleFonts.inter(
                                        color: VizareColors.champagneGold,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (adminEmail != null && adminEmail!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            adminEmail!,
                            style: GoogleFonts.inter(
                              color: VizareColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(color: VizareColors.obsidianBorder, height: 1),
                  const SizedBox(height: 12),

                  // 2. Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: [
                        _buildNavItem(
                          context: context,
                          view: AdminView.moderation,
                          title: 'Moderation Queue',
                          subtitle: 'Review & approve listings',
                          icon: Icons.verified_user_rounded,
                          badgeCount: pendingCount,
                        ),
                        const SizedBox(height: 6),
                        _buildNavItem(
                          context: context,
                          view: AdminView.listings,
                          title: 'Listings Management',
                          subtitle: 'All estate properties',
                          icon: Icons.home_work_rounded,
                        ),
                        const SizedBox(height: 6),
                        _buildNavItem(
                          context: context,
                          view: AdminView.users,
                          title: 'User Management',
                          subtitle: 'Accounts & permission roles',
                          icon: Icons.people_alt_rounded,
                        ),
                        const SizedBox(height: 6),
                        _buildNavItem(
                          context: context,
                          view: AdminView.analytics,
                          title: 'Platform Overview',
                          subtitle: 'Metrics & activity summary',
                          icon: Icons.insights_rounded,
                        ),
                      ],
                    ),
                  ),

                  // 3. Footer / Logout
                  const Divider(color: VizareColors.obsidianBorder, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: VisionGlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      borderRadius: 16,
                      backgroundColor: VizareColors.crimsonRed.withValues(alpha: 0.12),
                      border: Border.all(
                        color: VizareColors.crimsonRed.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                      onTap: onSignOut,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: VizareColors.crimsonRed,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
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
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required AdminView view,
    required String title,
    required String subtitle,
    required IconData icon,
    int? badgeCount,
  }) {
    final bool isSelected = currentView == view;

    return VisionGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      backgroundColor: isSelected
          ? VizareColors.champagneGold.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.03),
      border: Border.all(
        color: isSelected
            ? VizareColors.champagneGold.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.06),
        width: isSelected ? 1.4 : 1.0,
      ),
      onTap: () {
        Navigator.pop(context); // close drawer
        onViewSelected(view);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? VizareColors.champagneGold.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? VizareColors.champagneGold : VizareColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : VizareColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: VizareColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: VizareColors.crimsonRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount.toString(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
