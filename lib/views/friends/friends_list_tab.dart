import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsListTab extends StatelessWidget {
  final String currentUserId;

  const FriendsListTab({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final friendsRef =
        FirebaseFirestore.instance.collection('friends').doc(currentUserId);

    return StreamBuilder<DocumentSnapshot>(
      stream: friendsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final friendIds = data.entries
            .where((e) => e.value == true)
            .map((e) => e.key)
            .toList();

        if (friendIds.isEmpty) {
          return const Center(child: Text("No friends yet"));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: friendIds)
              .snapshots(),
          builder: (context, usersSnap) {
            if (!usersSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = usersSnap.data!.docs;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userDoc =
                    users[index].data() as Map<String, dynamic>? ?? {};
                final name =
                    "${userDoc['firstName'] ?? 'Unknown'} ${userDoc['lastName'] ?? ''}";
                final photoUrl = userDoc['profilePic'] as String? ?? '';
                final email = userDoc['email'] as String? ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(name),
                  subtitle: Text(email),
                );
              },
            );
          },
        );
      },
    );
  }
}
