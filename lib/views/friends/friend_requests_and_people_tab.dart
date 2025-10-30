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

  /// 🔹 Load both sent and received friend requests to hide from suggestions
  Future<void> _loadSentRequests() async {
    final firestore = FirebaseFirestore.instance;

    final sentSnapshot = await firestore
        .collection('friend_requests')
        .where('from', isEqualTo: widget.currentUserId)
        .get();

    final receivedSnapshot = await firestore
        .collection('friend_requests')
        .where('to', isEqualTo: widget.currentUserId)
        .get();

    setState(() {
      _sentRequests.addAll(sentSnapshot.docs.map((doc) => doc['to'] as String));
      _sentRequests
          .addAll(receivedSnapshot.docs.map((doc) => doc['from'] as String));
    });
  }

  /// 🔹 Send a friend request
  Future<void> _sendFriendRequest(String toUserId) async {
    final requestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    final existing = await requestsRef
        .where('from', isEqualTo: widget.currentUserId)
        .where('to', isEqualTo: toUserId)
        .get();

    if (existing.docs.isNotEmpty) return;

    try {
      await requestsRef.add({
        'from': widget.currentUserId,
        'to': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() => _sentRequests.add(toUserId));
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
    }
  }

  /// 🔹 Confirm friend and create chat in Realtime Database
  Future<void> _confirmFriend(String fromUserId, String reqId) async {
    final firestore = FirebaseFirestore.instance;
    final db = FirebaseDatabase.instance.ref();
    final currentUserId = widget.currentUserId;

    try {
      final batch = firestore.batch();

      final currentRef = firestore
          .collection('friends')
          .doc(currentUserId)
          .collection('list')
          .doc(fromUserId);

      final otherRef = firestore
          .collection('friends')
          .doc(fromUserId)
          .collection('list')
          .doc(currentUserId);

      batch.set(currentRef, {
        'mutual': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      batch.set(otherRef, {
        'mutual': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Delete friend request
      batch.delete(firestore.collection('friend_requests').doc(reqId));

      await batch.commit();

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
      debugPrint('❌ Error confirming friend: $e');
    }
  }

  /// 🔹 Friend request tile
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

  /// 🔹 User suggestion tile
  Widget _buildUserSuggestionTile(
      Map<String, dynamic> user, String userId, VoidCallback onAdd) {
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
        trailing: ElevatedButton(
          onPressed: onAdd,
          child: const Text("Add Friend"),
        ),
      ),
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
            child: Text(
              "Friend Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "People You May Know",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const SizedBox();
              final allUsers = userSnapshot.data!.docs;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('friends')
                    .doc(widget.currentUserId)
                    .collection('list')
                    .get(),
                builder: (context, friendsSnap) {
                  if (!friendsSnap.hasData) return const SizedBox();
                  final friends =
                      friendsSnap.data!.docs.map((e) => e.id).toSet();

                  final suggestions = allUsers.where((doc) {
                    final id = doc.id;
                    if (id == widget.currentUserId) return false;
                    if (friends.contains(id)) return false;
                    if (_sentRequests.contains(id)) return false;
                    return true;
                  }).toList();

                  if (suggestions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text("No suggestions right now"),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final user =
                          suggestions[index].data() as Map<String, dynamic>;
                      final userId = suggestions[index].id;
                      return _buildUserSuggestionTile(
                        user,
                        userId,
                        () => _sendFriendRequest(userId),
                      );
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
