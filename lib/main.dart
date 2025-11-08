import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:datem8/widgets/themes.dart';
import 'package:datem8/widgets/darkmode.dart';

// Pages
import 'package:datem8/onboarding/splash_page.dart';
import 'package:datem8/onboarding/welcome_page.dart';
import 'package:datem8/widgets/main_screen.dart';

// Services
import 'package:datem8/services/cloudinary_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DateM8App());
}

class DateM8App extends StatelessWidget {
  const DateM8App({super.key});

  @override
  Widget build(BuildContext context) {
    final cloudinaryService = CloudinaryService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DarkModeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'DateM8',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode, // ✅ This allows switching
          initialRoute: '/splash',
          routes: {
            '/splash': (context) =>
                SplashPage(cloudinaryService: cloudinaryService),
            '/welcome': (context) =>
                WelcomePage(cloudinaryService: cloudinaryService),
            '/main': (context) =>
                MainScreen(cloudinaryService: cloudinaryService),
          },
        );
      },
    );
  }
}
