import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/login/login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MarquezaApp());
}

class MarquezaApp extends StatelessWidget {
  const MarquezaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MARQUEZA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          primary: AppColors.blue,
        ),
        scaffoldBackgroundColor: AppColors.pageBg,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
