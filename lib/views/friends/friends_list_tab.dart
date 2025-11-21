import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "You have no friends yet.",
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final friendId = docs[i].id;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData || !userSnap.data!.exists)
                  return const SizedBox();

                final user =
                    userSnap.data!.data() as Map<String, dynamic>? ?? {};
                final fullName =
                    "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                        .trim();
                final profilePic = (user['profilePic'] ?? '').toString();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: profilePic.isNotEmpty
                              ? NetworkImage(profilePic)
                              : null,
                          child: profilePic.isEmpty
                              ? const Icon(Icons.person,
                                  size: 28, color: Colors.black38)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Name
                        Expanded(
                          child: Text(
                            fullName,
                            style: GoogleFonts.readexPro(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Status Badge (always "Friend")
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Friend",
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
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
