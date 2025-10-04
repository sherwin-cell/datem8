import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';

class FriendsPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const FriendsPage({super.key, required this.cloudinaryService});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final String currentUserId;
  late final TabController _tabController;
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Fetch user info with simple caching
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId]!;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    final data = doc.exists
        ? doc.data()!
        : {'firstName': 'Unknown', 'lastName': '', 'profilePic': ''};

    _userCache[userId] = data;
    return data;
  }

  /// Build avatar widget
  Widget _buildAvatar(String profilePic) => profilePic.isNotEmpty
      ? CircleAvatar(backgroundImage: NetworkImage(profilePic))
      : const CircleAvatar(child: Icon(Icons.person));

  /// Confirm friend request
  Future<void> _confirmFriend(String fromUserId, String reqId) async {
    final friendsRef = FirebaseFirestore.instance.collection('friends');
    final friendRequestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    try {
      // Add each other as friends
      await friendsRef
          .doc(currentUserId)
          .set({fromUserId: true}, SetOptions(merge: true));
      await friendsRef
          .doc(fromUserId)
          .set({currentUserId: true}, SetOptions(merge: true));

      // Delete the request
      await friendRequestsRef.doc(reqId).delete();

      // Switch to Friends List tab
      if (mounted) _tabController.animateTo(0);

      debugPrint('Friend confirmed!');
    } catch (e) {
      debugPrint('Error confirming friend: $e');
    }
  }

  /// Delete a friend request
  Future<void> _deleteFriendRequest(String fromUserId, String reqId) async {
    final friendsRef = FirebaseFirestore.instance.collection('friends');
    final friendRequestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    try {
      await friendRequestsRef.doc(reqId).delete();
      await friendsRef
          .doc(currentUserId)
          .update({fromUserId: FieldValue.delete()});
      await friendsRef
          .doc(fromUserId)
          .update({currentUserId: FieldValue.delete()});
    } catch (e) {
      debugPrint('Error deleting friend request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsRef =
        FirebaseFirestore.instance.collection('friends').doc(currentUserId);
    final friendRequestsRef =
        FirebaseFirestore.instance.collection('friend_requests');

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Friends List"),
            Tab(text: "Friend Requests"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Friends List Tab
              StreamBuilder<DocumentSnapshot>(
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
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getUserInfo(friendId),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(title: Text("Loading..."));
                          }

                          final userInfo = userSnapshot.data!;
                          return ListTile(
                            leading: _buildAvatar(userInfo['profilePic'] ?? ''),
                            title: Text(
                                "${userInfo['firstName']} ${userInfo['lastName']}"),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              // Friend Requests Tab
              StreamBuilder<QuerySnapshot>(
                stream: friendRequestsRef
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
                      final reqDoc = requests[index];
                      final fromUserId = reqDoc['from'];

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getUserInfo(fromUserId),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(title: Text("Loading..."));
                          }

                          final userInfo = userSnapshot.data!;
                          return ListTile(
                            leading: _buildAvatar(userInfo['profilePic'] ?? ''),
                            title: Text(
                                "${userInfo['firstName']} ${userInfo['lastName']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _confirmFriend(fromUserId, reqDoc.id),
                                  child: const Text("Confirm"),
                                ),
                                TextButton(
                                  onPressed: () => _deleteFriendRequest(
                                      fromUserId, reqDoc.id),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
