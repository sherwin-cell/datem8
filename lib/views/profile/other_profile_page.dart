import 'package:flutter/material.dart';

class OtherUserProfilePage extends StatelessWidget {
  final String userId;
  final String userName;
  final String avatarUrl; // Optional, can be empty

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(userName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child:
                  avatarUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("User ID: $userId"),
          ],
        ),
      ),
    );
  }
}
