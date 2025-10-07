import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/onboarding/welcome_page.dart';
import 'package:datem8/widgets/main_screen.dart';
import 'package:datem8/services/cloudinary_service.dart';

class SplashPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const SplashPage({super.key, required this.cloudinaryService});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return; // Prevent navigation errors if widget is disposed

    if (user != null) {
      // ✅ Already logged in → go to Main
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            cloudinaryService: widget.cloudinaryService,
          ),
        ),
      );
    } else {
      // ❌ Not logged in → go to Welcome
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomePage(
            cloudinaryService: widget.cloudinaryService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
