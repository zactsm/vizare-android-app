import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Full-Screen Luxury Shimmer Skeleton UI for PropertyDetailsPage.
/// Mirrors the exact dimensions and layout to prevent visual jumping when loading.
class PropertyDetailsSkeleton extends StatelessWidget {
  const PropertyDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VizareShimmer(
      child: Column(
        children: [
          // VisionOS Top Navigation Bar Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: VizareColors.glassFillElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: VizareColors.glassFillElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content Skeleton
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Price Tag Skeleton
                  const VizareSkeletonBlock(
                    width: 160,
                    height: 32,
                    borderRadius: 8,
                  ),
                  const SizedBox(height: 10),

                  // Property Title Skeleton (2 lines)
                  const VizareSkeletonBlock(
                    width: double.infinity,
                    height: 24,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 6),
                  const VizareSkeletonBlock(
                    width: 220,
                    height: 24,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 10),

                  // Location Skeleton
                  Row(
                    children: const [
                      VizareSkeletonBlock(
                        width: 16,
                        height: 16,
                        borderRadius: 8,
                      ),
                      SizedBox(width: 6),
                      VizareSkeletonBlock(
                        width: 140,
                        height: 14,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Main Hero Image Skeleton (16:10 aspect ratio)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: VizareColors.glassFillElevated,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Gallery Thumbnails Skeleton (Row of 3 items)
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        width: 68,
                        height: 68,
                        margin: const EdgeInsets.only(right: 10.0),
                        decoration: BoxDecoration(
                          color: VizareColors.glassFillElevated,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Architectural Specifications Header Skeleton
                  const VizareSkeletonBlock(
                    width: 180,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 12),

                  // 2x2 Bento Grid Skeleton
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: VizareColors.obsidianElevated.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: VizareColors.glassFillElevated,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  VizareSkeletonBlock(
                                    width: 70,
                                    height: 12,
                                    borderRadius: 4,
                                  ),
                                  SizedBox(height: 6),
                                  VizareSkeletonBlock(
                                    width: 50,
                                    height: 10,
                                    borderRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // About The Estate Header Skeleton
                  const VizareSkeletonBlock(
                    width: 140,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 10),

                  // Description Card Skeleton
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: VizareColors.obsidianSurface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        VizareSkeletonBlock(width: double.infinity, height: 12, borderRadius: 3),
                        SizedBox(height: 8),
                        VizareSkeletonBlock(width: double.infinity, height: 12, borderRadius: 3),
                        SizedBox(height: 8),
                        VizareSkeletonBlock(width: 200, height: 12, borderRadius: 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Action Bar Skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: VizareColors.obsidianSurface.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: VizareColors.champagneGold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: VizareColors.glassFillElevated,
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
