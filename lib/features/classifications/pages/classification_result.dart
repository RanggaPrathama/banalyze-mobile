import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/classifications/providers/classification_provider.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';

class ClassificationResultPage extends StatefulWidget {
  final Map<String, dynamic> resultData;

  const ClassificationResultPage({super.key, required this.resultData});

  @override
  State<ClassificationResultPage> createState() =>
      _ClassificationResultPageState();
}

class _ClassificationResultPageState extends State<ClassificationResultPage> {
  RipenessLevel get _ripeness {
    final label = widget.resultData['ripeness'] as String? ?? 'Ripe';
    debugPrint('Determining ripeness from label: $label');
    switch (label.toLowerCase()) {
      case 'unripe':
        return RipenessLevel.unripe;
      case 'partially_ripe':
        return RipenessLevel.partiallyRipe;
      case 'overripe':
        return RipenessLevel.overripe;
      case 'ripe':
      default:
        return RipenessLevel.ripe;
    }
  }

  Future<void> _saveToHistory() async {
    final provider = context.read<ClassificationProvider>();
    final success = await provider.saveHistory();
    if (!mounted) return;

    if (success) {
      AppSnackBar.success('Saved to history');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.main,
        (route) => false,
      );
    } else {
      AppSnackBar.error(provider.saveError ?? 'Failed to save history');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkCard : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final imagePath = widget.resultData['imagePath'] as String?;
    final confidence = widget.resultData['confidence'] as int? ?? 0;
    final description = widget.resultData['description'] as String? ?? '';
    final attributes =
        (widget.resultData['attributes'] as List<dynamic>?)?.cast<String>() ??
        [];
    final ripeness = _ripeness;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Classification Result',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline_rounded, color: subtextColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    // Image with detection box
                    _DetectedImageCard(
                      imagePath: imagePath,
                      ripeness: ripeness,
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 24),

                    // Status section
                    _StatusSection(
                      ripeness: ripeness,
                      confidence: confidence,
                      description: description,
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 24),

                    // Detected attributes
                    _AttributesSection(
                      attributes: attributes,
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 24),

                    // Ripeness timeline (Hide if unrecognized)
                    if (confidence >= ClassificationProvider.threshold) ...[
                      _RipenessTimeline(
                        current: ripeness,
                        isDark: isDark,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRouter.main,
                            (route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.document_scanner_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Scan Another',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (confidence >= ClassificationProvider.threshold) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: Consumer<ClassificationProvider>(
                          builder: (context, provider, _) {
                            return ElevatedButton.icon(
                              onPressed: provider.isSaving
                                  ? null
                                  : _saveToHistory,
                              icon: provider.isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.bookmark_add_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                provider.isSaving
                                    ? 'Saving...'
                                    : 'Save to History',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detected Image Card ──
class _DetectedImageCard extends StatelessWidget {
  final String? imagePath;
  final RipenessLevel ripeness;
  final bool isDark;
  final Color borderColor;

  const _DetectedImageCard({
    required this.imagePath,
    required this.ripeness,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: SizedBox(
          width: double.infinity,
          height: 220,
          child: imagePath != null
              ? Image.file(File(imagePath!), fit: BoxFit.cover)
              : const Center(child: Text('🍌', style: TextStyle(fontSize: 80))),
        ),
      ),
    );
  }
}

// ── Status Section ──
class _StatusSection extends StatelessWidget {
  final RipenessLevel ripeness;
  final int confidence;
  final String description;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const _StatusSection({
    required this.ripeness,
    required this.confidence,
    required this.description,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLowConfidence = confidence < ClassificationProvider.threshold;
    final displayColor = isLowConfidence ? AppColors.error : ripeness.color;
    final displayLabel = isLowConfidence ? 'Unrecognized' : ripeness.label;
    final displayAdvice = isLowConfidence
        ? 'Low confidence prediction'
        : ripeness.advice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STATUS label
        Text(
          'STATUS',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: subtextColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Ripeness label + confidence
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayLabel,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isLowConfidence ? AppColors.error : textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: displayColor,
                shape: BoxShape.circle,
              ),
            ),
            const Spacer(),
            // Confidence circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: displayColor, width: 3),
              ),
              child: Center(
                child: Text(
                  '$confidence%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: displayColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Advice badge
        Text(
          displayAdvice,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: displayColor,
          ),
        ),
        const SizedBox(height: 14),

        // Description
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: subtextColor.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: subtextColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Detected Attributes ──
class _AttributesSection extends StatelessWidget {
  final List<String> attributes;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;
  final Color borderColor;

  const _AttributesSection({
    required this.attributes,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Attributes',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: attributes.map((attr) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getAttrIcon(attr), size: 14, color: subtextColor),
                  const SizedBox(width: 6),
                  Text(
                    attr,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getAttrIcon(String attr) {
    final lower = attr.toLowerCase();
    if (lower.contains('sugar') || lower.contains('spot')) {
      return Icons.grain_rounded;
    }
    if (lower.contains('soft') || lower.contains('texture')) {
      return Icons.touch_app_rounded;
    }
    if (lower.contains('day')) return Icons.calendar_today_rounded;
    if (lower.contains('yellow') || lower.contains('color')) {
      return Icons.palette_rounded;
    }
    return Icons.circle;
  }
}

// ── Ripeness Timeline ──
class _RipenessTimeline extends StatelessWidget {
  final RipenessLevel current;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const _RipenessTimeline({
    required this.current,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      RipenessLevel.partiallyRipe,
      RipenessLevel.ripe,
      RipenessLevel.overripe,
    ];
    final currentIdx = stages.indexOf(current);
    final activeIdx = currentIdx == -1 ? 1 : currentIdx; // default to ripe

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ripeness Timeline',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),

        // Timeline bar
        Row(
          children: List.generate(stages.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line
              final segIdx = i ~/ 2;
              final filled = segIdx < activeIdx;
              return Expanded(
                child: Container(
                  height: 3,
                  color: filled
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                ),
              );
            }
            // Dot
            final stageIdx = i ~/ 2;
            final isActive = stageIdx == activeIdx;
            final isPast = stageIdx <= activeIdx;
            return Container(
              width: isActive ? 16 : 12,
              height: isActive ? 16 : 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPast ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isPast
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stages.map((s) {
            final isActive = s == current;
            return Text(
              s.label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? ripeness.color : subtextColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  RipenessLevel get ripeness => current;
}
