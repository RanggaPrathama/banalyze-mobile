import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';
import 'package:banalyze/features/profile/providers/profile_provider.dart';
import 'package:banalyze/features/profile/widgets/edit_profile_form_widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ProfileProvider>().loadFromUser(
          name: user.name,
          phone: user.phone,
          avatar: user.avatarUrl,
        );
      }
    });
  }

  Future<void> _pickAvatar() async {
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
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                'Change Avatar',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              _AvatarSourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _AvatarSourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                isDark: isDark,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        final authProvider = context.read<AuthProvider>();
        await context.read<ProfileProvider>().uploadAvatar(
          File(picked.path),
          authProvider: authProvider,
        );
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final authProvider = context.read<AuthProvider>();
    final success = await context.read<ProfileProvider>().saveProfile(
      authProvider: authProvider,
    );
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final cardColor = isDark ? AppColors.darkCard : Colors.grey.shade50;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;
    final fieldBg = isDark ? AppColors.darkSurface : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: profileProvider.isSaving
              ? null
              : () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: profileProvider.isUploadingAvatar ? null : _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: ClipOval(
                        child: profileProvider.isUploadingAvatar
                            ? Container(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : Colors.grey.shade200,
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : profileProvider.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: profileProvider.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.grey.shade200,
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: subtextColor,
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: subtextColor,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: bgColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Full Name
            EditProfileFieldLabel(text: 'Full Name', color: subtextColor),
            const SizedBox(height: 8),
            EditProfileStyledTextField(
              controller: profileProvider.fullNameController,
              icon: Icons.person_outline_rounded,
              textColor: textColor,
              hintColor: hintColor,
              fillColor: fieldBg,
              borderColor: borderColor,
            ),
            const SizedBox(height: 20),

            // Phone
            EditProfileFieldLabel(text: 'Phone Number', color: subtextColor),
            const SizedBox(height: 8),
            EditProfileStyledTextField(
              controller: profileProvider.phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textColor: textColor,
              hintColor: hintColor,
              fillColor: fieldBg,
              borderColor: borderColor,
            ),
            const SizedBox(height: 28),

            // Preferences
            // Text(
            //   'PREFERENCES',
            //   style: GoogleFonts.poppins(
            //     fontSize: 11,
            //     fontWeight: FontWeight.w700,
            //     color: hintColor,
            //     letterSpacing: 1,
            //   ),
            // ),
            // const SizedBox(height: 12),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            //   decoration: BoxDecoration(
            //     color: cardColor,
            //     borderRadius: BorderRadius.circular(14),
            //     border: Border.all(color: borderColor),
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         width: 36,
            //         height: 36,
            //         decoration: BoxDecoration(
            //           color: AppColors.primary.withValues(alpha: 0.12),
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: const Icon(
            //           Icons.notifications_active_outlined,
            //           size: 18,
            //           color: AppColors.primary,
            //         ),
            //       ),
            //       const SizedBox(width: 14),
            //       Expanded(
            //         child: Text(
            //           'Ripeness Alerts',
            //           style: GoogleFonts.poppins(
            //             fontSize: 14,
            //             fontWeight: FontWeight.w500,
            //             color: textColor,
            //           ),
            //         ),
            //       ),
            //       Switch.adaptive(
            //         value: profileProvider.ripenessAlerts,
            //         onChanged: profileProvider.setRipenessAlerts,
            //         activeColor: AppColors.primary,
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: profileProvider.isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: profileProvider.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.accent,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _AvatarSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkTextHint : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
