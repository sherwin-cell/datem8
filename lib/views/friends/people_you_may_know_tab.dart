import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datem8/widgets/pull_to_refresh_widget.dart'; // 👈 import your reusable widget

class PeopleYouMayKnowTab extends StatefulWidget {
  final String currentUserId;
  const PeopleYouMayKnowTab({super.key, required this.currentUserId});

  @override
  State<PeopleYouMayKnowTab> createState() => _PeopleYouMayKnowTabState();
}

class _PeopleYouMayKnowTabState extends State<PeopleYouMayKnowTab> {
  String _searchQuery = '';
  final Set<String> _sentRequests = {};

  /// 🔹 Send friend request
  Future<void> _sendFriendRequest(String toUserId) async {
    final requestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    final existing = await requestsRef
        .where('from', isEqualTo: widget.currentUserId)
        .where('to', isEqualTo: toUserId)
        .get();

    if (existing.docs.isNotEmpty) {
      _showSnack("You already sent a request");
      return;
    }

    await requestsRef.add({
      'from': widget.currentUserId,
      'to': toUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _sentRequests.add(toUserId);
    });

    _showSnack("Friend request sent");
  }

  /// 🔹 Cancel friend request
  Future<void> _cancelFriendRequest(String toUserId) async {
    final requestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    final existing = await requestsRef
        .where('from', isEqualTo: widget.currentUserId)
        .where('to', isEqualTo: toUserId)
        .get();

    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    setState(() {
      _sentRequests.remove(toUserId);
    });

    _showSnack("Friend request canceled");
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 🔹 Load sent requests (called on pull-to-refresh)
  Future<void> _loadSentRequests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: widget.currentUserId)
        .get();

    setState(() {
      _sentRequests
        ..clear()
        ..addAll(snapshot.docs.map((doc) => doc['to'] as String));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSentRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔎 Search Bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search people...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // 🔹 Users List with Pull to Refresh
        Expanded(
          child: PullToRefresh(
            onRefresh: _loadSentRequests, // 👈 just call this to reload
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != widget.currentUserId)
                    .map((doc) => {
                          'id': doc.id,
                          ...doc.data() as Map<String, dynamic>,
                        })
                    .where((data) {
                  final name =
                      "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
                          .toLowerCase();
                  final course =
                      (data['course'] ?? '').toString().toLowerCase();
                  return _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      course.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user['id'];
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final course = user['course'] ?? 'Student';
                    final profilePic = user['profilePic'] ?? '';
                    final isRequestSent = _sentRequests.contains(userId);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: profilePic.isNotEmpty
                              ? NetworkImage(profilePic)
                              : null,
                          child: profilePic.isEmpty
                              ? const Icon(Icons.person, size: 28)
                              : null,
                        ),
                        title: Text(
                          "$firstName $lastName",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(course),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isRequestSent ? Colors.grey : Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            if (isRequestSent) {
                              _cancelFriendRequest(userId);
                            } else {
                              _sendFriendRequest(userId);
                            }
                          },
                          child: Text(
                              isRequestSent ? "Cancel Request" : "Add Friend"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
