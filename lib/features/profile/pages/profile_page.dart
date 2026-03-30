import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/core/theme/theme_provider.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';
import 'package:banalyze/features/profile/widgets/profile_menu_tile.dart';
import 'package:banalyze/features/profile/widgets/profile_section_label.dart';
import 'package:banalyze/features/profile/widgets/profile_stat_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 47,
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : Colors.grey.shade200,
                    child: user?.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: subtextColor,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Banana Scout',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
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
                        'EXPERT SORTER',
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
                const SizedBox(height: 24),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: ProfileStatCard(
                        value: '124',
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
                        value: '98%',
                        label: 'ACCURACY',
                        cardColor: cardColor,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Preferences section
                ProfileSectionLabel(label: 'PREFERENCES', color: subtextColor),
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
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Dark Mode',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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
                const SizedBox(height: 20),

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
                const SizedBox(height: 10),
                ProfileMenuTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help Center',
                  cardColor: cardColor,
                  textColor: textColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 20),
                // Logout
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.pushReplacementNamed(context, '/login');
                      AppSnackBar.info('You have been logged out.');
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
                      backgroundColor: Colors.red.shade50.withValues(
                        alpha: isDark ? 0.1 : 1,
                      ),
                      foregroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
