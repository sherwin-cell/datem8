import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/views/auth/registration_page.dart';

class VerificationPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const VerificationPage({super.key, required this.cloudinaryService});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _isSending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending email: $e")),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (user != null && user.emailVerified) {
      _timer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RegistrationPage(cloudinaryService: widget.cloudinaryService),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "A verification email has been sent to your email address.\n"
              "Please check your inbox and click the link to verify your account.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSending ? null : _resendVerificationEmail,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Resend Verification Email"),
            ),
          ],
        ),
      ),
    );
  }
}
