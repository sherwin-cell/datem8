import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:datem8/services/friends_service.dart';

class FriendsRequestsAndPeopleTab extends StatefulWidget {
  final String currentUserId;

  const FriendsRequestsAndPeopleTab({
    super.key,
    required this.currentUserId,
  });

  @override
  State<FriendsRequestsAndPeopleTab> createState() =>
      _FriendsRequestsAndPeopleTabState();
}

class _FriendsRequestsAndPeopleTabState
    extends State<FriendsRequestsAndPeopleTab> {
  final FriendsService _friendsService = FriendsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final Set<String> _hiddenUserIds = {}; // Sent or received requests

  @override
  void initState() {
    super.initState();
    _loadHiddenUserIds();
  }

  /// 🔹 Load all users to hide from "People You May Know"
  Future<void> _loadHiddenUserIds() async {
    final sent = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: widget.currentUserId)
        .get();
    final received = await _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: widget.currentUserId)
        .get();

    setState(() {
      _hiddenUserIds.addAll(sent.docs.map((e) => e['to'] as String));
      _hiddenUserIds.addAll(received.docs.map((e) => e['from'] as String));
    });
  }

  /// 🔹 Confirm friend and auto-create chat in Realtime DB
  Future<void> _confirmFriend(String fromUserId, String requestId) async {
    try {
      await _friendsService.acceptFriendRequest(fromUserId);

      // Create chat
      final currentUserId = widget.currentUserId;
      final chatId = currentUserId.hashCode <= fromUserId.hashCode
          ? '$currentUserId-$fromUserId'
          : '$fromUserId-$currentUserId';

      final chatRef = _database.ref().child('chats').child(chatId);
      final chatSnap = await chatRef.get();

      if (!chatSnap.exists) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend added successfully 🎉")),
      );
    } catch (e) {
      debugPrint("❌ Error confirming friend: $e");
    }
  }

  /// 🔹 Friend request card
  Widget _buildFriendRequestCard(
      Map<String, dynamic> user, String reqId, String fromUserId) {
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    final profilePic = user['profilePic'] ?? '';

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
              onPressed: () async {
                await _firestore
                    .collection('friend_requests')
                    .doc(reqId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request deleted ❌")),
                );
              },
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Suggested user card
  Widget _buildSuggestedUserCard(Map<String, dynamic> user, String userId) {
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    final profilePic = user['profilePic'] ?? '';

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
          onPressed: () async {
            await _friendsService.sendFriendRequest(userId);
            setState(() => _hiddenUserIds.add(userId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Friend request sent to $name ✅")),
            );
          },
          child: const Text("Add Friend"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.currentUserId;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Friend Requests Section
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Friend Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('friend_requests')
                .where('to', isEqualTo: myId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final requests = snapshot.data!.docs;
              if (requests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("No requests right now"),
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
                    future:
                        _firestore.collection('users').doc(fromUserId).get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData || !userSnap.data!.exists)
                        return const SizedBox();
                      final user =
                          userSnap.data!.data() as Map<String, dynamic>;
                      return _buildFriendRequestCard(user, req.id, fromUserId);
                    },
                  );
                },
              );
            },
          ),

          // 🔹 People You May Know Section
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "People You May Know",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _friendsService.peopleYouMayKnow(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final people = snapshot.data!
                  .where((u) => !_hiddenUserIds.contains(u['uid']))
                  .toList();

              if (people.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("No suggestions right now"),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final user = people[index];
                  return _buildSuggestedUserCard(user, user['uid']);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
