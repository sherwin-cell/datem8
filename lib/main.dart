import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ✅ Correct Zego imports
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

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

  // 🔹 Change these between user_a and user_b for testing
  const String userID = "user_a";
  const String userName = "User A";

  // ✅ Initialize the invitation service
  await ZegoUIKitPrebuiltCallInvitationService().init(
    appID: 624522157,
    appSign: "9e0e20a7f50c97b7487134a23ad3c79b9febe175190e5e4269465ac4f667edc2",
    userID: userID,
    userName: userName,
    plugins: [ZegoUIKitSignalingPlugin()],
  );

  runApp(const DateM8App());
}

class DateM8App extends StatelessWidget {
  const DateM8App({super.key});

  @override
  Widget build(BuildContext context) {
    final cloudinaryService = CloudinaryService();

    return MaterialApp(
      title: 'DateM8',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) =>
            SplashPage(cloudinaryService: cloudinaryService),
        '/welcome': (context) =>
            WelcomePage(cloudinaryService: cloudinaryService),
        '/main': (context) => MainScreen(cloudinaryService: cloudinaryService),
      },
    );
  }
}
