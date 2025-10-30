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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _chatsEnsured = {}; // Track chats that already exist

  String _getChatId(String uid1, String uid2) =>
      uid1.hashCode <= uid2.hashCode ? '$uid1-$uid2' : '$uid2-$uid1';

  /// Ensures a chat exists for the friend pair (creates if not)
  Future<void> _ensureChatExists(String currentUserId, String friendId) async {
    final chatId = _getChatId(currentUserId, friendId);

    if (_chatsEnsured.contains(chatId)) return; // Already ensured

    final chatRef = FirebaseDatabase.instance.ref('chats/$chatId');
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'participants': {currentUserId: true, friendId: true},
        'timestamp': ServerValue.timestamp,
        'lastMessage': "",
        'lastMessageSenderId': "",
      });
    }

    _chatsEnsured.add(chatId);
  }

  /// Opens chat page and ensures chat exists
  Future<void> _openChat(String friendId, String friendName) async {
    final currentUserId = _auth.currentUser!.uid;
    await _ensureChatExists(currentUserId, friendId);

    final chatId = _getChatId(currentUserId, friendId);

    if (!context.mounted) return;
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
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0 &&
        now.day == date.day &&
        now.month == date.month &&
        now.year == date.year) {
      return DateFormat('hh:mm a').format(date);
    } else if (diff.inDays == 1 || (diff.inDays < 2 && now.day != date.day)) {
      return 'Yesterday ${DateFormat('hh:mm a').format(date)}';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatLastSeen(int? timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} h ago";
    return "${diff.inDays} d ago";
  }

  Widget _buildUserAvatar(String profilePic, String userId,
      {double radius = 28}) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('status/$userId').onValue,
      builder: (context, snapshot) {
        bool isOnline = false;
        int? lastSeen;

        final data = snapshot.data?.snapshot.value;
        if (data is Map) {
          isOnline = data['isOnline'] as bool? ?? false;
          lastSeen = data['lastSeen'] as int?;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundImage:
                  profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child: profilePic.isEmpty
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            if (!isOnline && lastSeen != null)
              Positioned(
                bottom: -18,
                left: 0,
                right: 0,
                child: Text(
                  _formatLastSeen(lastSeen),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final friendsSubCollection = FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUser.uid)
        .collection('list');

    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: Column(
        children: [
          // Horizontal friends list
          SizedBox(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream: friendsSubCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final friendsList =
                    snapshot.data!.docs.map((doc) => doc.id).toList();

                if (friendsList.isEmpty)
                  return const Center(child: Text("No friends yet"));

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: friendsList.length,
                  itemBuilder: (context, index) {
                    final friendId = friendsList[index];

                    return StreamBuilder<DocumentSnapshot>(
                      stream: usersCollection.doc(friendId).snapshots(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData)
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          );

                        final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>? ??
                            {};
                        final name =
                            "${userData['firstName'] ?? 'Unknown'} ${userData['lastName'] ?? ''}";
                        final profilePic = userData['profilePic'] ?? '';

                        return GestureDetector(
                          onTap: () => _openChat(friendId, name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                _buildUserAvatar(profilePic, friendId),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 60,
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
          // Chat list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: friendsSubCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final friendsList =
                    snapshot.data!.docs.map((doc) => doc.id).toList();

                if (friendsList.isEmpty)
                  return const Center(child: Text("No friends to chat with"));

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(friendsList.map((friendId) async {
                    await _ensureChatExists(currentUser.uid, friendId);

                    final chatId = _getChatId(currentUser.uid, friendId);
                    final chatSnap = await FirebaseDatabase.instance
                        .ref('chats/$chatId')
                        .get();
                    final chatData =
                        chatSnap.value as Map<dynamic, dynamic>? ?? {};
                    return {
                      'friendId': friendId,
                      'chatId': chatId,
                      'lastMessage': chatData['lastMessage'] ?? '',
                      'timestamp': chatData['timestamp'] ?? 0,
                      'lastSender': chatData['lastMessageSenderId'] ?? '',
                    };
                  }).toList()),
                  builder: (context, chatListSnapshot) {
                    if (!chatListSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final chats = chatListSnapshot.data!;
                    chats.sort((a, b) =>
                        (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final friendId = chat['friendId'];
                        final lastMessage = chat['lastMessage'];
                        final time = _formatTime(chat['timestamp']);

                        return StreamBuilder<DocumentSnapshot>(
                          stream: usersCollection.doc(friendId).snapshots(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData)
                              return const ListTile(
                                title: Text("Loading..."),
                                leading: CircleAvatar(),
                              );

                            final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>? ??
                                {};
                            final name =
                                "${userData['firstName'] ?? 'Unknown'} ${userData['lastName'] ?? ''}";
                            final profilePic = userData['profilePic'] ?? '';

                            return ListTile(
                              leading: _buildUserAvatar(profilePic, friendId),
                              title: Text(name),
                              subtitle: lastMessage.isNotEmpty
                                  ? Text(
                                      lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : const Text("Say hi 👋"),
                              trailing: time.isNotEmpty
                                  ? Text(
                                      time,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    )
                                  : null,
                              onTap: () => _openChat(friendId, name),
                            );
                          },
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
