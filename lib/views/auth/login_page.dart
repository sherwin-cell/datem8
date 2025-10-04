import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/main_screen.dart';
import 'package:datem8/views/auth/signup_page.dart';
import 'package:datem8/helper/app_colors.dart';
import 'package:datem8/helper/app.icons.dart';

class LoginPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const LoginPage({super.key, required this.cloudinaryService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MainScreen(cloudinaryService: widget.cloudinaryService),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";
      if (e.code == "user-not-found") {
        message = "No account found with this email.";
      } else if (e.code == "wrong-password") {
        message = "Incorrect password.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email first")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset link sent to $email")),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Error: ${e.message}";
      if (e.code == "user-not-found") {
        message = "No account found with this email.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpPage(cloudinaryService: widget.cloudinaryService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(AppIcons.message),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(AppIcons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: GestureDetector(
                    onLongPress: () => setState(() => _obscurePassword = false),
                    onLongPressUp: () =>
                        setState(() => _obscurePassword = true),
                    child: Transform.scale(
                      scale: 0.9,
                      child: Icon(
                        _obscurePassword
                            ? AppIcons.visibility
                            : AppIcons.visibilityOff,
                        color: AppColors.iconColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Login Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(color: AppColors.buttonText),
                        ),
                      ),
                    ),
              const SizedBox(height: 10),

              // Sign Up Redirect
              TextButton(
                onPressed: _goToRegister,
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
