// verification_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'registration_page.dart';

class VerificationPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const VerificationPage({super.key, required this.cloudinaryService});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _isLoading = false;

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RegistrationPage(cloudinaryService: widget.cloudinaryService),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email not verified yet.")),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resendVerificationEmail() async {
    try {
      setState(() => _isLoading = true);
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email resent.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email"), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "A verification email has been sent. Please check your inbox and verify your email to continue.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _checkVerification,
                        child: const Text("Continue"),
                      ),
                      TextButton(
                        onPressed: _resendVerificationEmail,
                        child: const Text("Resend Verification Email"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
