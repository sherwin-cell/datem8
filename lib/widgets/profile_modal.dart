import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:datem8/views/profile/other_profile_page.dart';
import 'package:datem8/services/cloudinary_service.dart';

class ProfileModal extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final CloudinaryService cloudinaryService;

  const ProfileModal({
    super.key,
    this.userData,
    required this.cloudinaryService,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final String displayName = (userData?['firstName'] != null)
        ? "${userData!['firstName']} ${userData!['lastName']}"
        : currentUser?.displayName ?? "Guest User";

    final String course = userData?['course'] ?? '';
    final String department = userData?['department'] ?? '';
    final String bio = userData?['bio'] ?? "Hi, I'm using this app";
    final int followers = userData?['followers'] ?? 0;
    final int following = userData?['following'] ?? 0;
    final String? profilePic = userData?['profilePic'] ?? currentUser?.photoURL;
    final bool isCurrentUser =
        userData == null || userData!['uid'] == currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                ? CachedNetworkImageProvider(profilePic)
                : null,
            child: (profilePic == null || profilePic.isEmpty)
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(displayName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 4),
          Text("$course - $department",
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatWidget(label: "Followers", count: followers),
              const SizedBox(width: 24),
              _StatWidget(label: "Following", count: following),
            ],
          ),
          const SizedBox(height: 16),
          Text(bio,
              style: const TextStyle(color: Colors.black87),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isCurrentUser) {
                      Navigator.pushNamed(context, '/profile');
                    } else if (userData?['uid'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfilePage(
                            userId: userData!['uid'],
                            userName: displayName,
                            cloudinaryService: cloudinaryService,
                            avatarUrl: profilePic,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text("View Profile"),
                ),
              ),
              const SizedBox(width: 10),
              if (!isCurrentUser)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text("+ Add Friend"),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String label;
  final int count;

  const _StatWidget({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("$count",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}

void showProfileModal(
  BuildContext context, {
  Map<String, dynamic>? userData,
  required CloudinaryService cloudinaryService,
}) {
  // Ensure UID exists
  final Map<String, dynamic>? dataWithUid = userData != null
      ? {...userData, 'uid': userData['uid'] ?? userData['id']}
      : null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileModal(
      userData: dataWithUid,
      cloudinaryService: cloudinaryService,
    ),
  );
}
