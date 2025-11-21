import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/onboarding/welcome_page.dart';
import 'package:datem8/widgets/main_screen.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:datem8/views/auth/verification_page.dart';

class SplashPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const SplashPage({super.key, required this.cloudinaryService});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward().whenComplete(_navigate);
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Reload user to get latest info
      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        // Verified → MainScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MainScreen(cloudinaryService: widget.cloudinaryService),
          ),
        );
      } else if (user != null) {
        // Not verified → VerificationPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationPage(
              cloudinaryService: widget.cloudinaryService,
            ),
          ),
        );
      }
    } else {
      // New user → WelcomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WelcomePage(cloudinaryService: widget.cloudinaryService),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0A), Color(0xFFFF3D6A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logog.png',
                    width: 140,
                    height: 140,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "DateM8",
                    style: GoogleFonts.readexPro(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 225, 204, 204),
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
