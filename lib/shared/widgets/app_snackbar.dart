import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/app.dart';

enum SnackBarType { success, error, info, warning }

class AppSnackBar {
  AppSnackBar._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show({
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Dismiss any existing snackbar
    _dismiss();

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _OverlaySnackBar(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () => _dismiss(),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () => _dismiss());
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void success(String message) =>
      show(message: message, type: SnackBarType.success);

  static void error(String message) =>
      show(message: message, type: SnackBarType.error);

  static void info(String message) =>
      show(message: message, type: SnackBarType.info);

  static void warning(String message) =>
      show(message: message, type: SnackBarType.warning);
}

class _OverlaySnackBar extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _OverlaySnackBar({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_OverlaySnackBar> createState() => _OverlaySnackBarState();
}

class _OverlaySnackBarState extends State<_OverlaySnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 20,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                widget.onDismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: _SnackBarContent(
                message: widget.message,
                type: widget.type,
                actionLabel: widget.actionLabel,
                onAction: () {
                  widget.onDismiss();
                  widget.onAction?.call();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackBarContent extends StatelessWidget {
  final String message;
  final SnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnackBarContent({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textColor,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onAction?.call(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFF0D1F12);
      case SnackBarType.error:
        return const Color(0xFF2D1215);
      case SnackBarType.warning:
        return const Color(0xFF2D2412);
      case SnackBarType.info:
        return const Color(0xFF121A2D);
    }
  }

  Color get _accentColor {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFF4CAF50);
      case SnackBarType.error:
        return const Color(0xFFEF5350);
      case SnackBarType.warning:
        return const Color(0xFFFFA726);
      case SnackBarType.info:
        return const Color(0xFF42A5F5);
    }
  }

  Color get _textColor {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFFB9F6CA);
      case SnackBarType.error:
        return const Color(0xFFFFCDD2);
      case SnackBarType.warning:
        return const Color(0xFFFFE0B2);
      case SnackBarType.info:
        return const Color(0xFFBBDEFB);
    }
  }

  IconData get _icon {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }
}
