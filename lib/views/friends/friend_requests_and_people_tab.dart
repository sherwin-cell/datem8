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

  Future<void> _deleteRequest(String reqId) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(reqId)
        .delete();
  }

  Future<void> _confirmFriend(String fromUserId, String reqId) async {
    final friendsRef = FirebaseFirestore.instance.collection('friends');
    final requestsRef =
        FirebaseFirestore.instance.collection('friend_requests');
    final db = FirebaseDatabase.instance.ref();

    // Batch write for mutual friendship
    final batch = FirebaseFirestore.instance.batch();
    batch.set(friendsRef.doc(widget.currentUserId), {fromUserId: true},
        SetOptions(merge: true));
    batch.set(friendsRef.doc(fromUserId), {widget.currentUserId: true},
        SetOptions(merge: true));
    batch.delete(requestsRef.doc(reqId));
    await batch.commit();

    // Realtime chat creation
    final chatId = widget.currentUserId.hashCode <= fromUserId.hashCode
        ? '${widget.currentUserId}-$fromUserId'
        : '$fromUserId-${widget.currentUserId}';
    final chatRef = db.child('chats').child(chatId);

    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'participants': {widget.currentUserId: true, fromUserId: true},
        'timestamp': ServerValue.timestamp,
        'lastMessage': 'You are now friends! 👋',
        'lastMessageSenderId': widget.currentUserId,
      });
      await chatRef.child('messages').push().set({
        'senderId': widget.currentUserId,
        'text': 'You are now friends! 👋',
        'timestamp': ServerValue.timestamp,
      });
    }
  }

  Widget _buildUserTile(Map<String, dynamic> user,
      {required VoidCallback onAction, required String actionText}) {
    final profilePic = user['profilePic'] ?? '';
    final name = "${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
          child: profilePic.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(name),
        trailing: ElevatedButton(onPressed: onAction, child: Text(actionText)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friends')
          .doc(widget.currentUserId)
          .snapshots(),
      builder: (context, friendsSnap) {
        final friendsData =
            friendsSnap.data?.data() as Map<String, dynamic>? ?? {};
        final friends = friendsData.keys.toSet();

        return RefreshIndicator(
          onRefresh: _loadSentRequests,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Friend Requests",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('friend_requests')
                      .where('to', isEqualTo: widget.currentUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();

                    final requests = snapshot.data!.docs
                        .where((r) => !friends.contains(r['from']))
                        .toList();

                    if (requests.isEmpty)
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("No friend requests"),
                      );

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
                            if (!userSnap.hasData)
                              return const ListTile(title: Text("Loading..."));
                            final user =
                                userSnap.data!.data() as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      (user['profilePic']?.isNotEmpty ?? false)
                                          ? NetworkImage(user['profilePic'])
                                          : null,
                                  child: (user['profilePic']?.isEmpty ?? true)
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                    "${user['firstName']} ${user['lastName']}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _confirmFriend(fromUserId, req.id),
                                      child: const Text("Confirm"),
                                    ),
                                    TextButton(
                                      onPressed: () => _deleteRequest(req.id),
                                      child: const Text("Delete"),
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
                ),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("People You May Know",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();

                    final users = snapshot.data!.docs
                        .where((doc) => doc.id != widget.currentUserId)
                        .map((doc) => {
                              'id': doc.id,
                              ...doc.data() as Map<String, dynamic>
                            })
                        .where((u) =>
                            !friends.contains(u['id']) &&
                            !_sentRequests.contains(u['id']))
                        .toList();

                    if (users.isEmpty)
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("No suggestions available"),
                      );

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserTile(
                          user,
                          onAction: () => _sendFriendRequest(user['id']),
                          actionText: "Add Friend",
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
