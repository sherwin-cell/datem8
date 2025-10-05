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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final friendsData =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};
        if (friendsData.isEmpty) {
          return const Center(child: Text("You have no friends"));
        }

        final friendIds = friendsData.keys.toList();
        return ListView.builder(
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            final friendId = friendIds[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text("Loading..."));
                }
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData['profilePic'] != null &&
                            userData['profilePic'].isNotEmpty
                        ? NetworkImage(userData['profilePic'])
                        : null,
                    child: userData['profilePic'] == null ||
                            userData['profilePic'].isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title:
                      Text("${userData['firstName']} ${userData['lastName']}"),
                );
              },
            );
          },
        );
      },
    );
  }
}
