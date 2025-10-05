import 'package:flutter/material.dart';

class OtherUserProfilePage extends StatelessWidget {
  final String userId;
  final String userName;
  final String avatarUrl; // Optional
  final String? status; // Optional user status or about info

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section with avatar
            Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 40),
              width: double.infinity,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  if (status != null && status!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      status!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("User ID"),
                  subtitle: Text(userId),
                ),
              ),
            ),
            // Optionally, you can add buttons like "Message" or "Add Friend"
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to chat or send message
                      },
                      icon: const Icon(Icons.message),
                      label: const Text("Message"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Friend request logic
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text("Add Friend"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
