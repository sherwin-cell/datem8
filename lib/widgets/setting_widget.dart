import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:datem8/views/profile/edit_profile.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/darkmode.dart';

class SettingsIconButton extends StatelessWidget {
  final CloudinaryService cloudinaryService;
  final String userId;

  const SettingsIconButton({
    super.key,
    required this.cloudinaryService,
    required this.userId,
  });

  void _showSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      _showSnackBar(context, "No email linked to this account.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      _showSnackBar(context, "Password reset email sent. Check your inbox!");
    } on FirebaseAuthException catch (e) {
      _showSnackBar(context, "Error: ${e.message}");
    }
  }

  Future<void> _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@datem8.app',
      query: 'subject=DateM8 Support&body=Hello DateM8 Team,',
    );
    if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    Color confirmColor = Colors.red,
  }) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        content: Text(content,
            style: GoogleFonts.inter(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(_, true),
            child: Text(confirmText,
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Verify Password",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: "Enter your password",
            labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, null),
            child: Text("Cancel",
                style: GoogleFonts.inter(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(_, controller.text),
            child:
                Text("Confirm", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final confirm = await _showConfirmationDialog(
      context,
      title: "Delete Account",
      content:
          "Deleting your account is permanent and cannot be undone. Are you sure?",
    );

    if (confirm != true) return;

    final password = await _showPasswordDialog(context);
    if (password == null || password.isEmpty) return;

    try {
      final credential =
          EmailAuthProvider.credential(email: user!.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      await user.delete();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    } on FirebaseAuthException catch (e) {
      _showSnackBar(context, "Error: ${e.message}");
    }
  }

  Future<void> _showAccountDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "No email found";
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Account Details',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.email,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: theme.colorScheme.onSurface),
              title: Text('Edit Profile',
                  style: GoogleFonts.inter(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(_);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                          cloudinaryService: cloudinaryService,
                          userId: userId)),
                );
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.lock_reset, color: theme.colorScheme.onSurface),
              title: Text('Reset Password',
                  style: GoogleFonts.inter(color: theme.colorScheme.onSurface)),
              onTap: () async {
                Navigator.pop(_);
                await _sendPasswordResetEmail(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Account',
                  style: GoogleFonts.inter(color: Colors.red)),
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: Text('Close',
                style: GoogleFonts.inter(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await _showConfirmationDialog(
      context,
      title: 'Log Out',
      content: 'Do you want to log out of your account?',
      confirmText: 'Log Out',
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DarkModeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return PopupMenuButton<String>(
          icon: Image.asset(
            'assets/icons/menu.png',
            width: 20,
            height: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onSelected: (value) async {
            switch (value) {
              case 'account':
                _showAccountDialog(context);
                break;
              case 'about':
                await _showSimpleDialog(context, 'About DateM8',
                    "DateM8 is a student-focused matchmaking app that helps you connect with like-minded individuals.\n\nVersion: 1.0.0\nTeam DateM8 💜");
                break;
              case 'terms':
                await _showSimpleDialog(context, 'Terms of Service',
                    "By using DateM8, you agree to follow our community guidelines and provide accurate information.");
                break;
              case 'contact':
                _contactSupport();
                break;
              case 'logout':
                _confirmLogout(context);
                break;
            }
          },
          itemBuilder: (context) => [
            _buildMenuItem(
                'account', 'Account', 'assets/icons/user-account.png'),
            _buildMenuItem('about', 'About', 'assets/icons/info.png'),
            _buildMenuItem(
                'terms', 'Terms of Service', 'assets/icons/terms-of-use.png'),
            _buildMenuItem('contact', 'Contact Support',
                'assets/icons/customer-support.png',
                iconColor: const Color.fromARGB(255, 188, 13, 204)),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'darkmode',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny,
                      color: isDark ? Colors.grey : Colors.orange),
                  Switch(
                    value: isDark,
                    onChanged: (_) {
                      DarkModeController.toggleTheme();
                      Navigator.pop(context);
                    },
                  ),
                  Icon(Icons.dark_mode,
                      color: isDark ? Colors.blue : Colors.grey),
                ],
              ),
            ),
            const PopupMenuDivider(),
            _buildMenuItem('logout', 'Log Out', 'assets/icons/exit.png',
                isRed: true),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, String title, String iconPath,
      {Color? iconColor, bool isRed = false}) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        leading: Image.asset(iconPath, width: 20, height: 20, color: iconColor),
        title: Text(title,
            style: GoogleFonts.inter(color: isRed ? Colors.red : null)),
      ),
    );
  }

  Future<void> _showSimpleDialog(
      BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface)),
        content: Text(content,
            style: GoogleFonts.inter(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: Text('Close',
                style: GoogleFonts.inter(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
