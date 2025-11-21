import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:datem8/services/friends_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendsRequestsAndPeopleTab extends StatefulWidget {
  final String currentUserId;

  const FriendsRequestsAndPeopleTab({super.key, required this.currentUserId});

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

  Future<void> _confirmFriend(String fromUserId, String requestId) async {
    final theme = Theme.of(context);
    try {
      await _friendsService.acceptFriendRequest(fromUserId);

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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Friend added successfully 🎉",
              style:
                  GoogleFonts.readexPro(color: theme.colorScheme.onBackground)),
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error confirming friend: $e");
    }
  }

  Widget _buildFriendRequestCard(
      Map<String, dynamic> user, String reqId, String fromUserId) {
    final theme = Theme.of(context);
    final fullName =
        "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    final profilePic = user['profilePic'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              backgroundImage:
                  profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child: profilePic.isEmpty
                  ? Icon(Icons.person,
                      size: 28, color: theme.colorScheme.onSurface)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "sent you a friend request",
                    style: GoogleFonts.readexPro(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => _confirmFriend(fromUserId, reqId),
                  child: Text("Confirm",
                      style: GoogleFonts.readexPro(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () async {
                    await _firestore
                        .collection('friend_requests')
                        .doc(reqId)
                        .delete();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Request deleted ❌",
                            style: GoogleFonts.readexPro(
                                color: theme.colorScheme.onBackground)),
                        backgroundColor:
                            theme.colorScheme.secondary.withOpacity(0.1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text("Delete",
                      style: GoogleFonts.readexPro(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Keep the box for suggested users
  Widget _buildSuggestedUserCard(Map<String, dynamic> user, String userId) {
    final theme = Theme.of(context);
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    final profilePic = user['profilePic'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
          backgroundImage:
              profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
          child: profilePic.isEmpty
              ? Icon(Icons.person, size: 24, color: theme.colorScheme.onSurface)
              : null,
        ),
        title: Text(
          name,
          style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            foregroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: () async {
            await _friendsService.sendFriendRequest(userId);
            if (!mounted) return;
            setState(() => _hiddenUserIds.add(userId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Friend request sent to $name ✅",
                    style: GoogleFonts.readexPro(
                        color: theme.colorScheme.onBackground)),
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text("Add Friend", style: GoogleFonts.readexPro(fontSize: 12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = widget.currentUserId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friend Requests Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Friend Requests",
              style: GoogleFonts.readexPro(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground),
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
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "No requests right now",
                    style: GoogleFonts.readexPro(
                        color: theme.colorScheme.onBackground.withOpacity(0.6)),
                  ),
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

          // People You May Know Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "People May You Know",
              style: GoogleFonts.readexPro(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground),
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
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "No suggestions right now",
                    style: GoogleFonts.readexPro(
                        color: theme.colorScheme.onBackground.withOpacity(0.6)),
                  ),
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
