import 'package:flutter/material.dart';
import 'package:banalyze/features/splash/pages/splash_page.dart';
import 'package:banalyze/shared/widgets/app_navigation.dart';
import 'package:banalyze/features/article/pages/article_detail_page.dart';
import 'package:banalyze/features/auth/pages/login_page.dart';
import 'package:banalyze/features/auth/pages/register_page.dart';
import 'package:banalyze/features/classifications/pages/image_review.dart';
import 'package:banalyze/features/classifications/pages/classification_result.dart';
import 'package:banalyze/features/history/pages/scan_detail_page.dart';
import 'package:banalyze/features/history/pages/scan_error_page.dart';
import 'package:banalyze/features/profile/pages/edit_profile_page.dart';
import 'package:banalyze/features/profile/pages/about_app_page.dart';
import 'package:banalyze/features/profile/pages/help_center_page.dart';

/// Centralized route names and navigation helpers.
class AppRouter {
  AppRouter._();

  // Route names
  static const String splash = '/';
  static const String main = '/main';
  static const String scan = '/scan';
  static const String articleDetail = '/article-detail';
  static const String login = '/login';
  static const String register = '/register';
  static const String scanDetail = '/scan-detail';
  static const String classificationResult = '/classification-result';
  static const String scanError = '/scan-error';
  static const String editProfile = '/edit-profile';
  static const String aboutApp = '/about-app';
  static const String helpCenter = '/help-center';

  /// Route map for [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(const SplashPage());
      case main:
        return _fade(const MainNavigation());
      case scan:
        final imagePath = settings.arguments as String;
        return _slide(ImageReviewPage(imagePath: imagePath));
      case classificationResult:
        final data = settings.arguments as Map<String, dynamic>;
        return _slide(ClassificationResultPage(resultData: data));
      case articleDetail:
        final articleId = settings.arguments as String;
        return _slide(ArticleDetailPage(articleId: articleId));
      case login:
        return _fade(const LoginPage());
      case register:
        return _fade(const RegisterPage());
      case scanDetail:
        final scanId = settings.arguments as String;
        return _slide(ScanDetailPage(scanId: scanId));
      case scanError:
        return _slide(const ScanErrorPage());
      case editProfile:
        return _slide(const EditProfilePage());
      case aboutApp:
        return _slide(const AboutAppPage());
      case helpCenter:
        return _slide(const HelpCenterPage());
      default:
        return _fade(
          const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }

  /// Fade transition
  static Route<dynamic> _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Slide-up transition (for modal-like pages such as scan)
  static Route<dynamic> _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(position: tween, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
