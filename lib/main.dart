import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Transparent status bar to blend with map preview.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AqrabMasjidApp());
}

class AqrabMasjidApp extends StatelessWidget {
  const AqrabMasjidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.cairoTextTheme(
      Theme.of(context).textTheme,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
      surface: AppConstants.creamBackground,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.creamBackground,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            textStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
