import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/theme/app_theme.dart';
import 'package:banalyze/core/theme/theme_provider.dart';
import 'package:banalyze/core/constants/app_strings.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';
import 'package:banalyze/features/profile/providers/profile_provider.dart';
import 'package:banalyze/features/article/providers/article_provider.dart';
import 'package:banalyze/features/classifications/repositories/classification_repository.dart';
import 'package:banalyze/features/classifications/providers/classification_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BanalyzeApp extends StatelessWidget {
  const BanalyzeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              ClassificationProvider(ClassificationRepository())..initModel(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
