import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';
import 'package:banalyze/features/home/providers/home_provider.dart';

/// Header section with avatar, greeting, and notification bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    // final bellBg = isDark ? AppColors.darkCard : AppColors.white;
    // final bellBorder = isDark ? AppColors.darkBorder : AppColors.border;

    final user = context.watch<AuthProvider>().user;
    final greeting = context.watch<HomeProvider>().greeting;
    final userName = user?.name.isNotEmpty == true
        ? user!.name
        : 'Bananalyze User';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            image: user?.avatarUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(user!.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image: Image.asset(
                      'assets/images/default_avatar.png',
                    ).image,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting text
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hintColor,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                userName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        // Container(
        //   width: 40,
        //   height: 40,
        //   decoration: BoxDecoration(
        //     color: bellBg,
        //     shape: BoxShape.circle,
        //     border: Border.all(color: bellBorder),
        //   ),
        //   child: Icon(Icons.notifications_outlined, size: 20, color: textColor),
        // ),
      ],
    );
  }
}
