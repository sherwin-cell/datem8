import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'verification_page.dart';

class SignUpPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const SignUpPage({super.key, required this.cloudinaryService});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@thelewiscollege\.edu\.ph$");
    return emailRegex.hasMatch(email);
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnack("Please fill in all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack("Invalid email format");
      return;
    }

    if (password != confirmPassword) {
      _showSnack("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationPage(
              cloudinaryService: widget.cloudinaryService,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Sign up failed";
      if (e.code == 'email-already-in-use') {
        message = "You already have an account";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak";
      } else if (e.message != null) {
        message = e.message!;
      }
      if (mounted) _showSnack(message);
    } catch (e) {
      if (mounted) _showSnack("An unexpected error occurred");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Sign Up"), automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Transform.scale(
                      scale: 0.9,
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                    child: Transform.scale(
                      scale: 0.9,
                      child: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createAccount,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text("Create Account"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
