import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'chat_conversation_page.dart';
import 'package:datem8/services/cloudinary_service.dart';

class ChatPage extends StatelessWidget {
  final CloudinaryService cloudinaryService;

  const ChatPage({super.key, required this.cloudinaryService});

  String _getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  Future<void> _openChat(BuildContext context, String currentUserId,
      String otherUserId, String otherUserName) async {
    final chatId = _getChatId(currentUserId, otherUserId);
    final chatRef = FirebaseDatabase.instance.ref('chats/$chatId');

    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'participants': {currentUserId: true, otherUserId: true},
        'timestamp': ServerValue.timestamp,
        'lastMessage': "",
      });
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(
          chatId: chatId,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          cloudinaryService: cloudinaryService,
        ),
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final friendsDoc =
        FirebaseFirestore.instance.collection('friends').doc(currentUser.uid);

    return Scaffold(
      appBar: AppBar(title: const Text("Message")),
      body: Column(
        children: [
          /// --- FRIENDS ROW (Top) ---
          SizedBox(
            height: 100,
            child: StreamBuilder<DocumentSnapshot>(
              stream: friendsDoc.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final friendsData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                if (friendsData.isEmpty) {
                  return const Center(child: Text("No friends yet"));
                }

                final friendIds = friendsData.keys.toList();

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: friendIds.length,
                  itemBuilder: (context, index) {
                    final friendId = friendIds[index];

                    return FutureBuilder<DocumentSnapshot>(
                      future: usersCollection.doc(friendId).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>? ??
                            {};
                        final name =
                            "${userData['firstName'] ?? 'Unknown'} ${userData['lastName'] ?? ''}";
                        final profilePic = userData['profilePic'] ?? '';

                        return GestureDetector(
                          onTap: () => _openChat(
                              context, currentUser.uid, friendId, name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: profilePic.isNotEmpty
                                      ? NetworkImage(profilePic)
                                      : null,
                                  child: profilePic.isEmpty
                                      ? const Icon(Icons.person, size: 30)
                                      : null,
                                ),
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

          /// --- CHAT LIST (Below Friends Row) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != currentUser.uid)
                    .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['uid'] = doc.id;
                  return data;
                }).toList();

                if (users.isEmpty)
                  return const Center(child: Text("No users available"));

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user['uid'] ?? "";
                    final chatId = _getChatId(currentUser.uid, userId);
                    final chatRef =
                        FirebaseDatabase.instance.ref('chats/$chatId');

                    return StreamBuilder<DatabaseEvent>(
                      stream: chatRef.onValue,
                      builder: (context, chatSnapshot) {
                        String lastMessage = "";
                        String time = "";

                        if (chatSnapshot.hasData &&
                            chatSnapshot.data!.snapshot.value != null) {
                          final data = chatSnapshot.data!.snapshot.value
                              as Map<dynamic, dynamic>;
                          lastMessage = (data['lastMessage'] ?? "").toString();
                          final ts = data['timestamp'];
                          if (ts != null && ts is int) time = _formatTime(ts);
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (user['profilePic'] ?? "").isNotEmpty
                                    ? NetworkImage(user['profilePic'])
                                    : null,
                            child: (user['profilePic'] ?? "").isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                              "${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}"),
                          subtitle: lastMessage.isNotEmpty
                              ? Text(lastMessage,
                                  maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: time.isNotEmpty
                              ? Text(time,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey))
                              : null,
                          onTap: () => _openChat(
                            context,
                            currentUser.uid,
                            userId,
                            "${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}",
                          ),
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
