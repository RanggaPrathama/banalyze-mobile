import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/classifications/providers/classification_provider.dart';
import 'package:banalyze/features/classifications/providers/realtime_classification_provider.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';

// ── Entry Point ───────────────────────────────────────────────────────────────

/// Creates its own scoped [RealtimeClassificationProvider] so the camera
/// controller is automatically disposed when the page is removed from the tree.
class RealtimeClassificationPage extends StatelessWidget {
  const RealtimeClassificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Re-use the already-initialised TFLite model from the global provider
      // to avoid loading the interpreter twice in memory.
      create: (ctx) => RealtimeClassificationProvider(
        ctx.read<ClassificationProvider>().repository,
      )..init(),
      child: const _RealtimeView(),
    );
  }
}

// ── Main View ─────────────────────────────────────────────────────────────────

class _RealtimeView extends StatefulWidget {
  const _RealtimeView();

  @override
  State<_RealtimeView> createState() => _RealtimeViewState();
}

class _RealtimeViewState extends State<_RealtimeView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isCapturing = false;
  late final AnimationController _pulseAnim;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock to portrait for consistent camera preview framing
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Pulsing animation for "DETECTION ACTIVE" dot
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<RealtimeClassificationProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      provider.controller?.dispose();
    } else if (state == AppLifecycleState.resumed && provider.isInitialized) {
      provider.init();
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _onGetFullAnalysis() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    final rtProvider = context.read<RealtimeClassificationProvider>();
    final classProvider = context.read<ClassificationProvider>();

    // 1. Capture still from live feed
    final File? capturedFile = await rtProvider.captureStill();
    if (!mounted) return;

    if (capturedFile == null) {
      AppSnackBar.error('Could not capture frame. Please try again.');
      rtProvider.resumeInference();
      setState(() => _isCapturing = false);
      return;
    }

    // 2. Run full classification via the shared provider
    classProvider.setImage(capturedFile);
    await classProvider.classify();
    if (!mounted) return;

    if (classProvider.status == ClassificationStatus.error) {
      AppSnackBar.error(classProvider.errorMessage ?? 'Classification failed.');
      rtProvider.resumeInference();
      setState(() => _isCapturing = false);
      return;
    }

    // 3. Navigate to result page; resume inference if user pops back
    Navigator.pushNamed(
      context,
      AppRouter.classificationResult,
      arguments: classProvider.toResultData(),
    ).then((_) {
      if (mounted) {
        setState(() => _isCapturing = false);
        rtProvider.resumeInference();
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Consumer<RealtimeClassificationProvider>(
        builder: (context, provider, _) {
          if (provider.error != null) {
            return _ErrorView(error: provider.error!);
          }
          if (!provider.isInitialized) {
            return const _LoadingView();
          }
          return _buildLiveView(provider);
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Live Detection',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLiveView(RealtimeClassificationProvider provider) {
    final size = MediaQuery.of(context).size;
    // Square scan frame: 76% of screen width
    final frameSize = size.width * 0.76;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera Preview ────────────────────────────────────────────────
        CameraPreview(provider.controller!),

        // ── Darkened overlay (top + bottom) ──────────────────────────────
        _buildGradientOverlay(),

        // ── Scan Frame + Detection Card ───────────────────────────────────
        Center(
          child: SizedBox(
            width: frameSize,
            height: frameSize,
            child: Stack(
              children: [
                // Scan bracket corners
                Positioned.fill(
                  child: CustomPaint(painter: _ScanBracketPainter()),
                ),
                // Detection info card
                Center(
                  child: _DetectionCard(
                    provider: provider,
                    pulseScale: _pulseScale,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── AI System Label (side) ────────────────────────────────────────
        Positioned(
          right: 10,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                'AI CORE SYSTEM V2.4',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.22),
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // ── Bottom Action Button ──────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: _AnalysisButton(
                isCapturing: _isCapturing,
                onPressed: _onGetFullAnalysis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.70),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.80),
            ],
            stops: const [0.0, 0.22, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}

// ── Scan Bracket Painter ──────────────────────────────────────────────────────

class _ScanBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cl = 30.0; // corner line length
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(0, cl), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(cl, 0), paint);

    // Top-right
    canvas.drawLine(Offset(w - cl, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cl), paint);

    // Bottom-right
    canvas.drawLine(Offset(w, h - cl), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w - cl, h), paint);

    // Bottom-left
    canvas.drawLine(Offset(cl, h), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cl), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Detection Card ────────────────────────────────────────────────────────────

class _DetectionCard extends StatelessWidget {
  final RealtimeClassificationProvider provider;
  final Animation<double> pulseScale;
  const _DetectionCard({required this.provider, required this.pulseScale});

  Color get _classColor {
    if (provider.isBelowThreshold) return Colors.white.withValues(alpha: 0.7);
    switch (provider.detectedClass) {
      case 'Ripe':
        return AppColors.ripe;
      case 'Partially Ripe':
        return AppColors.primary;
      case 'Overripe':
        return AppColors.overripe;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DETECTION ACTIVE badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: pulseScale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'DETECTION ACTIVE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Class name
          Text(
            provider.detectedClass,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Confidence badge
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: provider.isBelowThreshold
                ? const SizedBox.shrink()
                : Container(
                    key: const ValueKey('confidence'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _classColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _classColor.withValues(alpha: 0.50),
                      ),
                    ),
                    child: Text(
                      '${provider.confidencePercent}% Accuracy',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _classColor,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Threshold warning
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: provider.isBelowThreshold
                  ? const Color(0xFFE74C3C).withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.isBelowThreshold
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  size: 13,
                  color: provider.isBelowThreshold
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFF2ECC71),
                ),
                const SizedBox(width: 5),
                Text(
                  provider.isBelowThreshold
                      ? 'Accuracy < Threshold(${provider.thresholdValue}%): Undefined'
                      : 'Above threshold (${provider.thresholdValue}%)',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: provider.isBelowThreshold
                        ? const Color(0xFFE74C3C)
                        : const Color(0xFF2ECC71),
                    fontWeight: FontWeight.w500,
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

// ── GET FULL ANALYSIS Button ──────────────────────────────────────────────────

class _AnalysisButton extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onPressed;
  const _AnalysisButton({required this.isCapturing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isCapturing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isCapturing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Analyzing…',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GET FULL ANALYSIS',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Initialising camera…',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              color: Colors.white38,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Camera Unavailable',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
              ),
              label: Text(
                'Go Back',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
