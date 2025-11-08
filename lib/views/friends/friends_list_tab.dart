import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsListTab extends StatelessWidget {
  final String currentUserId;

  const FriendsListTab({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final friendsRef = FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUserId)
        .collection('list');

    return StreamBuilder<QuerySnapshot>(
      stream: friendsRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("You have no friends yet."));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final friendId = docs[i].id;
            final isMutual = docs[i]['mutual'] ?? false;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();
                final user = userSnap.data!.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text("${user['firstName']} ${user['lastName']}"),
                  trailing: Text(
                    isMutual ? "Friend" : "Pending",
                    style: TextStyle(
                      color: isMutual
                          ? const Color.fromARGB(255, 239, 237, 239)
                          : Colors.orange,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
