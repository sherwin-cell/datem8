import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:datem8/views/profile/edit_profile.dart';
import 'package:datem8/services/cloudinary_service.dart';

class SettingsIconButton extends StatelessWidget {
  final CloudinaryService cloudinaryService;
  final String userId;

  const SettingsIconButton({
    super.key,
    required this.cloudinaryService,
    required this.userId,
  });

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      _showSnackBar(context, "No email associated with this account.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      _showSnackBar(context, "Password reset email sent! Check your inbox.");
    } on FirebaseAuthException catch (e) {
      _showSnackBar(context, "Error: ${e.message}");
    }
  }

  Future<void> _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@datem8.app',
      query: 'subject=DateM8 App Support&body=Hi DateM8 Team,',
    );
    if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    // Step 1: Confirm deletion
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    // Step 2: Re-authenticate
    final password = await showDialog<String>(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Confirm Password"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Enter your password"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(_, null),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(_, controller.text),
                child: const Text("Confirm")),
          ],
        );
      },
    );

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

  // 🆕 ACCOUNT DIALOG (with email added)
  Future<void> _showAccountDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "No email found";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display user's email address
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading:
                    const Icon(Icons.email_outlined, color: Colors.deepPurple),
                title: Text(
                  email,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(_);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(
                      cloudinaryService: cloudinaryService,
                      userId: userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Change Password'),
              onTap: () async {
                Navigator.pop(_);
                await _sendPasswordResetEmail(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Account',
                  style: TextStyle(color: Colors.red)),
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings, color: Colors.black),
      onSelected: (value) {
        switch (value) {
          case 'account':
            _showAccountDialog(context);
            break;
          case 'about':
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('About DateM8 ❤️'),
                content: const Text(
                  "DateM8 is a modern matchmaking app designed to help students connect "
                  "with like-minded individuals based on their department, interests, and goals.\n\nVersion: 1.0.0\nDeveloped by Team DateM8 💜",
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(_),
                      child: const Text('Close'))
                ],
              ),
            );
            break;
          case 'terms':
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text("Terms of Service"),
                content: const Text(
                  "By using DateM8, you agree to respect others, keep your information accurate, "
                  "and follow our community guidelines.",
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(_),
                      child: const Text('Close'))
                ],
              ),
            );
            break;
          case 'privacy':
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text("Privacy Policy"),
                content: const Text(
                  "DateM8 respects your privacy. We collect minimal data and never share your information "
                  "without your consent.",
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(_),
                      child: const Text('Close'))
                ],
              ),
            );
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
        const PopupMenuItem(
          value: 'account',
          child: ListTile(leading: Icon(Icons.person), title: Text('Account')),
        ),
        const PopupMenuItem(
          value: 'about',
          child:
              ListTile(leading: Icon(Icons.info_outline), title: Text("About")),
        ),
        const PopupMenuItem(
          value: 'terms',
          child: ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text("Terms of Service")),
        ),
        const PopupMenuItem(
          value: 'privacy',
          child: ListTile(
              leading: Icon(Icons.lock_outline), title: Text("Privacy Policy")),
        ),
        const PopupMenuItem(
          value: 'contact',
          child: ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text("Contact Support")),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout", style: TextStyle(color: Colors.red))),
        ),
      ],
    );
  }
}
