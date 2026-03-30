import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/shared/models/scan_history.dart';
import 'package:banalyze/features/history/repositories/history_repository.dart';

class ScanDetailPage extends StatefulWidget {
  final String scanId;

  const ScanDetailPage({super.key, required this.scanId});

  @override
  State<ScanDetailPage> createState() => _ScanDetailPageState();
}

class _ScanDetailPageState extends State<ScanDetailPage> {
  final HistoryRepository _repository = HistoryRepository();
  late Future<ScanHistory> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getHistoryById(widget.scanId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Details',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<ScanHistory>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load scan details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = _repository.getHistoryById(widget.scanId);
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        'Retry',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return _ScanDetailContent(scan: snapshot.data!);
        },
      ),
    );
  }
}

class _ScanDetailContent extends StatelessWidget {
  final ScanHistory scan;

  const _ScanDetailContent({required this.scan});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        children: [
          // Banana image
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: scan.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: scan.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Text('🍌', style: TextStyle(fontSize: 80)),
                      ),
                    )
                  : const Center(
                      child: Text('🍌', style: TextStyle(fontSize: 80)),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Analysis result label
          Text(
            'ANALYSIS RESULT',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subtextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scan.ripeness.label,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scan.ripeness.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scan.ripeness.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  scan.ripeness.advice,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scan.ripeness.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Stats grid — 2x2
          Row(
            children: [
              Expanded(
                child: _DetailStatCard(
                  icon: Icons.verified_outlined,
                  label: 'CONFIDENCE',
                  value: '${(scan.confidence * 100).round()}%',
                  iconColor: AppColors.ripe,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailStatCard(
                  icon: Icons.memory_rounded,
                  label: 'MODEL',
                  value: scan.model,
                  iconColor: AppColors.primary,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailStatCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'DATE',
                  value: _formatDate(scan.dateTime),
                  iconColor: Colors.blue,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailStatCard(
                  icon: Icons.schedule_rounded,
                  label: 'TIME',
                  value: _formatTime(scan.dateTime),
                  iconColor: Colors.purple,
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Share button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text(
                'Share Result',
                style: GoogleFonts.poppins(
                  fontSize: 15,
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}\n${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:$m $period';
  }
}

class _DetailStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;
  final Color borderColor;

  const _DetailStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
