import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/welcome',
      (route) => false, // Clear all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings, color: Colors.black),
      onSelected: (value) {
        if (value == 'settings') {
          _showSnackBar(context, "Settings page coming soon!");
        } else if (value == 'about') {
          _showSnackBar(context, "DateM8 v1.0 – Made with ❤️");
        } else if (value == 'logout') {
          _logout(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
          ),
        ),
        const PopupMenuItem(
          value: 'about',
          child: ListTile(
            leading: Icon(Icons.info),
            title: Text("About"),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
