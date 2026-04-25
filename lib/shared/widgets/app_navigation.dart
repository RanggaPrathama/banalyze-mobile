import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/core/constants/app_strings.dart';
import 'package:banalyze/core/version_checker.dart';
import 'package:banalyze/features/history/providers/history_provider.dart';
import 'package:banalyze/features/profile/providers/profile_provider.dart';
import 'package:banalyze/features/home/pages/home_page.dart';
import 'package:banalyze/features/history/pages/history_page.dart';
import 'package:banalyze/features/article/pages/article_list_page.dart';
import 'package:banalyze/features/profile/pages/profile_page.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/shared/utils/image_crop_helper.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final HistoryProvider _historyProvider;

  @override
  void initState() {
    super.initState();
    _historyProvider = HistoryProvider()..loadInitial();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) VersionChecker.checkAndShowUpdateDialog(context);
    });
  }

  @override
  void dispose() {
    _historyProvider.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Refresh history setiap kali tab History dibuka
    if (index == 1 && index != _currentIndex) {
      _historyProvider.refresh();
    }
    // Refresh profile stats setiap kali tab Profile dibuka
    if (index == 3 && index != _currentIndex) {
      context.read<ProfileProvider>().loadStats();
    }
    setState(() => _currentIndex = index);
  }

  void _onScanTapped() {
    _showImageSourcePicker();
  }

  Future<void> _showImageSourcePicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: subtextColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Image Source',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how to capture your banana image',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    subtitle: 'Use camera to capture',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose from Gallery',
                    subtitle: 'Select existing photo',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: subtextColor.withValues(alpha: 0.18),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or try Realtime feature',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: subtextColor.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: subtextColor.withValues(alpha: 0.18),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LiveDetectionButton(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        AppRouter.realtimeClassification,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      File finalImage = File(picked.path);

      if (source == ImageSource.gallery) {
        // Gallery: interactive crop UI so user selects the banana area
        final cropped = await cropImageInteractive(
          finalImage,
          context: context,
        );
        if (cropped == null || !mounted) return;
        finalImage = cropped;
      } else {
        // Camera: auto center-crop to square (focus on center object)
        finalImage = await centerCropSquare(finalImage);
        if (!mounted) return;
      }

      Navigator.of(
        context,
      ).pushNamed(AppRouter.scan, arguments: finalImage.path);
    } catch (_) {
      // User cancelled or permission denied — stay on main
    }
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cardColor,
        title: Text(
          'Exit Banalyze?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: textColor,
          ),
        ),
        content: Text(
          'Are you sure you want to exit the application?',
          style: GoogleFonts.poppins(fontSize: 13, color: subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: subtextColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Yes, Exit',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? AppColors.darkSurface : AppColors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomePage(),
            ChangeNotifierProvider.value(
              value: _historyProvider,
              child: const HistoryPage(),
            ),
            const ArticleListPage(),
            const ProfilePage(),
          ],
        ),
        extendBody: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _ScanButton(onTap: _onScanTapped),
        bottomNavigationBar: BottomAppBar(
          color: barColor,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          padding: EdgeInsets.zero,
          elevation: 16,
          shadowColor: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : AppColors.shadow,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: AppStrings.navHome,
                    isActive: _currentIndex == 0,
                    onTap: () => _onTabTapped(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.access_time_outlined,
                    activeIcon: Icons.access_time_filled,
                    label: AppStrings.navHistory,
                    isActive: _currentIndex == 1,
                    onTap: () => _onTabTapped(1),
                  ),
                ),
                const Expanded(child: SizedBox()), // Area for center FAB
                Expanded(
                  child: _NavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: AppStrings.navGuide,
                    isActive: _currentIndex == 2,
                    onTap: () => _onTabTapped(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: AppStrings.navProfile,
                    isActive: _currentIndex == 3,
                    onTap: () => _onTabTapped(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // closes Scaffold
    ); // closes PopScope
  }
}

/// Center floating scan button — like GoPay QRIS scan.
class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_rounded,
              size: 26,
              color: AppColors.accent,
            ),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single navigation item with animated scale on active state.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.darkNavActive : AppColors.navActive;
    final inactiveColor = isDark
        ? AppColors.darkNavInactive
        : AppColors.navInactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isActive ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDetectionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LiveDetectionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D0D1A), Color(0xFF12192E), Color(0xFF0A1628)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container with sparkle badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.accent,
                      size: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Realtime AI Detection',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AI',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Try the new real-time detection feature using your camera',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            // Tri-star sparkle on right
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 15),
                const SizedBox(height: 4),
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary.withValues(alpha: 0.45),
                  size: 10,
                ),
                const SizedBox(height: 3),
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary.withValues(alpha: 0.2),
                  size: 7,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subtextColor, size: 22),
          ],
        ),
      ),
    );
  }
}
