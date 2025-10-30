import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class FriendsRequestsAndPeopleTab extends StatefulWidget {
  final String currentUserId;

  const FriendsRequestsAndPeopleTab({super.key, required this.currentUserId});

  @override
  State<FriendsRequestsAndPeopleTab> createState() =>
      _FriendsRequestsAndPeopleTabState();
}

class _FriendsRequestsAndPeopleTabState
    extends State<FriendsRequestsAndPeopleTab> {
  final Set<String> _sentRequests = {};

  @override
  void initState() {
    super.initState();
    _loadSentRequests();
  }

  Future<void> _loadSentRequests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: widget.currentUserId)
        .get();

    setState(() {
      _sentRequests.addAll(snapshot.docs.map((doc) => doc['to'] as String));
    });
  }

  // ignore: unused_element
  Future<void> _sendFriendRequest(String toUserId) async {
    final requestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    final existing = await requestsRef
        .where('from', isEqualTo: widget.currentUserId)
        .where('to', isEqualTo: toUserId)
        .get();

    if (existing.docs.isNotEmpty) return;

    await requestsRef.add({
      'from': widget.currentUserId,
      'to': toUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _sentRequests.add(toUserId));
  }

  Future<void> _confirmFriend(String fromUserId, String reqId) async {
    final firestore = FirebaseFirestore.instance;
    final db = FirebaseDatabase.instance.ref();
    final currentUserId = widget.currentUserId;

    try {
      await firestore
          .collection('friends')
          .doc(currentUserId)
          .collection('list')
          .doc(fromUserId)
          .set({
        'mutual': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await firestore
          .collection('friends')
          .doc(fromUserId)
          .collection('list')
          .doc(currentUserId)
          .set({
        'mutual': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await firestore.collection('friend_requests').doc(reqId).delete();

      // Create chat in Realtime Database
      final chatId = currentUserId.hashCode <= fromUserId.hashCode
          ? '$currentUserId-$fromUserId'
          : '$fromUserId-$currentUserId';

      final chatRef = db.child('chats').child(chatId);
      final chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        await chatRef.set({
          'participants': {currentUserId: true, fromUserId: true},
          'timestamp': ServerValue.timestamp,
          'lastMessage': 'You are now friends! 👋',
          'lastMessageSenderId': currentUserId,
        });

        await chatRef.child('messages').push().set({
          'senderId': currentUserId,
          'text': 'You are now friends! 👋',
          'timestamp': ServerValue.timestamp,
        });
      }

      setState(() => _sentRequests.remove(fromUserId));
    } catch (e) {
      debugPrint("Error confirming friend: $e");
    }
  }

  Widget _buildFriendRequestTile(
      Map<String, dynamic> user, String reqId, String fromUserId) {
    final profilePic = user['profilePic'] ?? '';
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
          child: profilePic.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _confirmFriend(fromUserId, reqId),
              child: const Text("Confirm"),
            ),
            TextButton(
              onPressed: () => FirebaseFirestore.instance
                  .collection('friend_requests')
                  .doc(reqId)
                  .delete(),
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPendingTile(Map<String, dynamic> user) {
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    return ListTile(
      title: Text(name),
      trailing: const Text("Pending", style: TextStyle(color: Colors.orange)),
    );
  }

  // ignore: unused_element
  Widget _buildUserTile(Map<String, dynamic> user, VoidCallback onAdd) {
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    return ListTile(
      title: Text(name),
      trailing: ElevatedButton(onPressed: onAdd, child: const Text("Add")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Friend Requests",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('friend_requests')
                .where('to', isEqualTo: widget.currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final requests = snapshot.data!.docs;
              if (requests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("No requests"),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final fromUserId = req['from'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(fromUserId)
                        .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();
                      final user =
                          userSnap.data!.data() as Map<String, dynamic>;
                      return _buildFriendRequestTile(user, req.id, fromUserId);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
