import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'chat_conversation_page.dart';
import 'package:datem8/services/cloudinary_service.dart';

class ChatPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;
  const ChatPage({super.key, required this.cloudinaryService});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  final _firestore = FirebaseFirestore.instance;

  String _getChatId(String uid1, String uid2) =>
      uid1.hashCode <= uid2.hashCode ? '$uid1-$uid2' : '$uid2-$uid1';

  Future<void> _ensureChatExists(String currentUserId, String friendId) async {
    final chatId = _getChatId(currentUserId, friendId);
    final chatRef = _db.child('chats/$chatId');
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'participants': {currentUserId: true, friendId: true},
        'timestamp': ServerValue.timestamp,
        'lastMessage': '',
        'lastMessageSenderId': '',
      });
    }
  }

  Future<void> _openChat(String friendId, String friendName) async {
    final currentUserId = _auth.currentUser!.uid;
    await _ensureChatExists(currentUserId, friendId);
    final chatId = _getChatId(currentUserId, friendId);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(
          chatId: chatId,
          currentUserId: currentUserId,
          otherUserId: friendId,
          otherUserName: friendName,
          cloudinaryService: widget.cloudinaryService,
        ),
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('hh:mm a').format(date)}';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget _buildUserAvatar(String profilePic, String userId,
      {double radius = 26}) {
    return StreamBuilder<DatabaseEvent>(
      stream: _db.child('status/$userId/isOnline').onValue,
      builder: (context, snapshot) {
        final isOnline = snapshot.data?.snapshot.value == true;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundImage:
                  profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child: profilePic.isEmpty
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            if (isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser!;
    final friendsRef = _firestore
        .collection('friends')
        .doc(currentUser.uid)
        .collection('list');
    final usersRef = _firestore.collection('users');

    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: Column(
        children: [
          // 🔹 Friend list
          SizedBox(
            height: 130,
            child: StreamBuilder<QuerySnapshot>(
              stream: friendsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final friendIds = snapshot.data!.docs.map((e) => e.id).toList();
                if (friendIds.isEmpty) {
                  return const Center(child: Text("No friends yet"));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: friendIds.length,
                  itemBuilder: (context, i) {
                    final friendId = friendIds[i];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: usersRef.doc(friendId).snapshots(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final user =
                            userSnap.data!.data() as Map<String, dynamic>;
                        final name =
                            "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                .trim();
                        final profilePic = user['profilePic'] ?? '';

                        return GestureDetector(
                          onTap: () => _openChat(friendId, name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildUserAvatar(profilePic, friendId),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
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
            ),
          ),
          const Divider(height: 1),

          // 🔹 Chat List (optimized)
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _db
                  .child('chats')
                  .orderByChild('participants/${currentUser.uid}')
                  .equalTo(true)
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No recent chats"));
                }

                final rawData = snapshot.data!.snapshot.value as Map;
                final chats = <Map<String, dynamic>>[];

                rawData.forEach((chatId, chatDataRaw) {
                  final chatData = Map<String, dynamic>.from(chatDataRaw);
                  final deletedFor =
                      Map<String, dynamic>.from(chatData['deletedFor'] ?? {});
                  if (deletedFor[currentUser.uid] == true) return;

                  chats.add({
                    'chatId': chatId,
                    'participants': Map<String, dynamic>.from(
                        chatData['participants'] ?? {}),
                    'lastMessage': chatData['lastMessage'] ?? '',
                    'timestamp': chatData['timestamp'] ?? 0,
                  });
                });

                chats.sort((a, b) =>
                    (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

                if (chats.isEmpty) {
                  return const Center(child: Text("No recent chats"));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, i) {
                    final chat = chats[i];
                    final friendId = chat['participants']
                        .keys
                        .firstWhere((id) => id != currentUser.uid);
                    final lastMsg = chat['lastMessage'].toString().isEmpty
                        ? "No messages yet"
                        : chat['lastMessage'];
                    final time = _formatTime(chat['timestamp']);

                    return StreamBuilder<DocumentSnapshot>(
                      stream: usersRef.doc(friendId).snapshots(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists) {
                          return const ListTile(title: Text("Unknown user"));
                        }

                        final user =
                            userSnap.data!.data() as Map<String, dynamic>;
                        final name =
                            "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                .trim();
                        final profilePic = user['profilePic'] ?? '';

                        return ListTile(
                          leading: _buildUserAvatar(profilePic, friendId),
                          title: Text(name),
                          subtitle: Text(
                            lastMsg == "[Image]" ? "[Image]" : lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () => _openChat(friendId, name),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
