import 'package:banalyze/core/api_client.dart';
import 'package:flutter/material.dart';
import 'package:banalyze/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDioInterceptors();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BanalyzeApp());
}
