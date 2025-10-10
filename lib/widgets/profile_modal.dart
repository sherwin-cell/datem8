import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileModal extends StatelessWidget {
  final Map<String, dynamic>? userData; // Optional Firestore user data

  const ProfileModal({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Determine user info
    final String displayName =
        userData != null && userData!['firstName'] != null
            ? "${userData!['firstName']} ${userData!['lastName']}"
            : (currentUser?.displayName ?? "Guest User");

    final String email = userData != null
        ? userData!['email'] ?? "No email"
        : (currentUser?.email ?? "No email");

    final String? profilePic =
        userData != null ? userData!['profilePic'] : currentUser?.photoURL;

    // Determine if this is the logged-in user
    final bool isCurrentUser =
        userData == null || userData!['email'] == currentUser?.email;

    return FractionallySizedBox(
      heightFactor: 0.5, // Fixed height for consistent modal appearance
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Profile picture
              CircleAvatar(
                radius: 50,
                backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                    ? CachedNetworkImageProvider(profilePic)
                    : null,
                child: (profilePic == null || profilePic.isEmpty)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),

              // Email
              Text(
                email,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Primary action button
              ElevatedButton(
                onPressed: () {
                  if (isCurrentUser) {
                    Navigator.pushNamed(context, '/profile');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Messaging coming soon")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isCurrentUser ? "View Profile" : "Message"),
              ),

              // Logout button only for current user
              if (isCurrentUser)
                TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/welcome');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the modal
void showProfileModal(
  BuildContext context, {
  Map<String, dynamic>? userData,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProfileModal(userData: userData),
  );
}
