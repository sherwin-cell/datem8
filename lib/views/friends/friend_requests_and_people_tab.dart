import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsRequestsAndPeopleTab extends StatefulWidget {
  final String currentUserId;

  const FriendsRequestsAndPeopleTab({super.key, required this.currentUserId});

  @override
  State<FriendsRequestsAndPeopleTab> createState() =>
      _FriendsRequestsAndPeopleTabState();
}

class _FriendsRequestsAndPeopleTabState
    extends State<FriendsRequestsAndPeopleTab> {
  final Set<String> _sentRequests = {}; // Sent requests
  final Set<String> _friends = {}; // Current friends

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadSentRequests();
  }

  Future<void> _loadFriends() async {
    final doc = await FirebaseFirestore.instance
        .collection('friends')
        .doc(widget.currentUserId)
        .get();

    if (doc.exists) {
      setState(() {
        _friends.addAll((doc.data() ?? {}).keys);
      });
    }
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

  Future<void> _confirmFriend(String fromUserId, String reqId) async {
    final friendsRef = FirebaseFirestore.instance.collection('friends');
    final requestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    // Add each other as friends
    await friendsRef
        .doc(widget.currentUserId)
        .set({fromUserId: true}, SetOptions(merge: true));
    await friendsRef
        .doc(fromUserId)
        .set({widget.currentUserId: true}, SetOptions(merge: true));

    // Delete the request
    await requestsRef.doc(reqId).delete();

    // Update UI immediately
    setState(() {
      _friends.add(fromUserId); // now the request will be filtered out
      _sentRequests.remove(fromUserId);
    });
  }

  Future<void> _deleteRequest(String reqId) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(reqId)
        .delete();
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

    setState(() {
      _sentRequests.add(toUserId);
    });
  }

  Widget _buildUserTile(Map<String, dynamic> user,
      {required VoidCallback onAction, required String actionText}) {
    final profilePic = user['profilePic'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
          child: profilePic.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text("${user['firstName']} ${user['lastName']}"),
        trailing: ElevatedButton(
          onPressed: onAction,
          child: Text(actionText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadFriends();
        await _loadSentRequests();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friend Requests Section
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                // Filter out requests that are already friends
                final requests = snapshot.data!.docs
                    .where((r) => !_friends.contains(r['from']))
                    .toList();

                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("No friend requests"),
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
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData)
                          return const ListTile(title: Text("Loading..."));

                        final user =
                            userSnapshot.data!.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  user['profilePic']?.isNotEmpty == true
                                      ? NetworkImage(user['profilePic'])
                                      : null,
                              child: user['profilePic']?.isEmpty == true
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

            // People You May Know Section
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("People You May Know",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != widget.currentUserId)
                    .map((doc) =>
                        {'id': doc.id, ...doc.data() as Map<String, dynamic>})
                    .where((data) =>
                        !_friends.contains(data['id']) &&
                        !_sentRequests.contains(data['id']))
                    .toList();

                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("No suggestions available"),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserTile(user,
                        onAction: () => _sendFriendRequest(user['id']),
                        actionText: "Add Friend");
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
