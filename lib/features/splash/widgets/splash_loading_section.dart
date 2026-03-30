import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/splash/providers/splash_provider.dart';

class SplashLoadingSection extends StatelessWidget {
  final Animation<double> progressAnimation;

  const SplashLoadingSection({super.key, required this.progressAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, _) {
        final percent = (progressAnimation.value * 100).toInt();
        final provider = context.watch<SplashProvider>();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  provider.loadingText,
                  key: ValueKey(provider.loadingText),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STEP ${provider.currentStep} OF ${provider.totalSteps}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading AI Model v1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
