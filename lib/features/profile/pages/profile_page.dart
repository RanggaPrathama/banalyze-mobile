import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/core/version_checker.dart';
import 'package:banalyze/core/theme/theme_provider.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';
import 'package:banalyze/features/profile/providers/profile_provider.dart';
import 'package:banalyze/features/profile/widgets/profile_menu_tile.dart';
import 'package:banalyze/features/profile/widgets/profile_section_label.dart';
import 'package:banalyze/features/profile/widgets/profile_stat_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initVersion();
  }

  Future<void> _initVersion() async {
    final version = await VersionChecker.getCurrentVersion();
    if (mounted) setState(() => _appVersion = version);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profileProvider = context.watch<ProfileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final bg = isDark ? AppColors.darkBackground : null;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.accent;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade600;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientMid,
                    AppColors.gradientEnd,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            onRefresh: () => context.read<ProfileProvider>().loadStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Avatar
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 39,
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade200,
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user!.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                              ),
                            )
                          : ClipOval(
                              child: Image.asset(
                                'assets/images/default_avatar.png',
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? 'Banana Scout',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ripe.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.ripe,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified User',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ripe,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: ProfileStatCard(
                          value: '${profileProvider.totalScans}',
                          label: 'TOTAL SCANS',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtextColor: subtextColor,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProfileStatCard(
                          value: profileProvider.accuracy,
                          label: 'ACCURACY',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtextColor: subtextColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Preferences section
                  ProfileSectionLabel(
                    label: 'PREFERENCES',
                    color: subtextColor,
                  ),
                  const SizedBox(height: 10),
                  ProfileMenuTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    cardColor: cardColor,
                    textColor: textColor,
                    borderColor: borderColor,
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),
                  // _MenuTile(
                  //   icon: Icons.notifications_outlined,
                  //   label: 'Notification Settings',
                  //   cardColor: cardColor,
                  //   textColor: textColor,
                  //   borderColor: borderColor,
                  // ),
                  // _MenuTile(
                  //   icon: Icons.lock_outline_rounded,
                  //   label: 'Privacy & Security',
                  //   cardColor: cardColor,
                  //   textColor: textColor,
                  //   borderColor: borderColor,
                  // ),
                  // _MenuTile(
                  //   icon: Icons.download_outlined,
                  //   label: 'Data Export',
                  //   cardColor: cardColor,
                  //   textColor: textColor,
                  //   borderColor: borderColor,
                  // ),

                  // Dark mode toggle
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dark Mode',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Support section
                  ProfileSectionLabel(label: 'SUPPORT', color: subtextColor),
                  const SizedBox(height: 10),
                  ProfileMenuTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About App',
                    cardColor: cardColor,
                    textColor: textColor,
                    borderColor: borderColor,
                    onTap: () => Navigator.pushNamed(context, '/about-app'),
                  ),
                  const SizedBox(height: 8),
                  ProfileMenuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help Center',
                    cardColor: cardColor,
                    textColor: textColor,
                    borderColor: borderColor,
                    onTap: () => Navigator.pushNamed(context, '/help-center'),
                  ),
                  const SizedBox(height: 16),
                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            title: Text(
                              'Keluar Aplikasi?',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to log out Banalyze ?',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: subtextColor,
                              ),
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
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Yes, Log Out',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          context.read<AuthProvider>().logout();
                          Navigator.pushReplacementNamed(context, '/login');
                          AppSnackBar.info('You have been logged out.');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(
                        'Log Out',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade900),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App version
                  Text(
                    _appVersion.isNotEmpty ? 'v$_appVersion' : '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
