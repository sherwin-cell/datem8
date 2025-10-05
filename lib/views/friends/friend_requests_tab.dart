import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestsTab extends StatelessWidget {
  final String currentUserId;
  const FriendRequestsTab({super.key, required this.currentUserId});

  Future<void> _confirmFriend(String fromUserId, String reqId) async {
    final friendsRef = FirebaseFirestore.instance.collection('friends');
    final requestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    await friendsRef
        .doc(currentUserId)
        .set({fromUserId: true}, SetOptions(merge: true));
    await friendsRef
        .doc(fromUserId)
        .set({currentUserId: true}, SetOptions(merge: true));

    await requestsRef.doc(reqId).delete();
  }

  Future<void> _deleteRequest(String reqId) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(reqId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('to', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return const Center(child: Text("No friend requests"));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final fromUserId = req['from'];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text("Loading..."));
                }
                final user = userSnapshot.data!.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profilePic'] != null &&
                            user['profilePic'].isNotEmpty
                        ? NetworkImage(user['profilePic'])
                        : null,
                    child:
                        user['profilePic'] == null || user['profilePic'].isEmpty
                            ? const Icon(Icons.person)
                            : null,
                  ),
                  title: Text("${user['firstName']} ${user['lastName']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _confirmFriend(fromUserId, req.id),
                        child: const Text("Confirm"),
                      ),
                      TextButton(
                        onPressed: () => _deleteRequest(req.id),
                        child: const Text("Delete"),
                      ),
                    ],
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
