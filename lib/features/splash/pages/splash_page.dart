import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';
import 'package:banalyze/features/splash/providers/splash_provider.dart';
import 'package:banalyze/features/splash/widgets/splash_loading_section.dart';
import 'package:banalyze/features/splash/widgets/splash_logo.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/core/constants/app_colors.dart';

/// Entry point for the splash screen.
/// Provides [SplashProvider] and delegates rendering to [_SplashView].
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SplashProvider(),
      child: const _SplashView(),
    );
  }
}

/// Handles animations and delegates state updates to [SplashProvider].
class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Delegate progress updates to the provider
    _progressController.addListener(() {
      context.read<SplashProvider>().updateProgress(_progressAnimation.value);
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigateToMain();
    });

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _progressController.forward();
    });
  }

  Future<void> _navigateToMain() async {
    if (!mounted) return;

    final isLoggedIn = await context.read<AuthProvider>().checkAuthStatus();

    debugPrint('Navigation decision: isLoggedIn=$isLoggedIn');
    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppRouter.main);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    AppColors.darkGradientStart,
                    AppColors.darkGradientMid,
                    AppColors.darkGradientEnd,
                  ]
                : const [
                    AppColors.gradientStart,
                    AppColors.gradientMid,
                    AppColors.gradientEnd,
                  ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const SplashLogo(),
                const SizedBox(height: 20),
                Text(
                  'Get Ready!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Smart Banana Ripeness Detection',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(flex: 3),
                SplashLoadingSection(progressAnimation: _progressAnimation),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
