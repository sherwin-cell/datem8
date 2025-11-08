import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'chat_conversation_page.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'chat_actions.dart';

class ChatPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;
  const ChatPage({super.key, required this.cloudinaryService});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final ChatActions _chatActions = ChatActions();

  String? _currentUserId;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.userChanges().listen((user) {
      if (user != null) {
        setState(() => _currentUserId = user.uid);
        _setUserOnline(user.uid);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserOffline();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;
    final statusRef = _db.child('status/$_currentUserId');
    if (state == AppLifecycleState.resumed) {
      statusRef.set({'isOnline': true});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      statusRef.set({'isOnline': false});
    }
  }

  void _setUserOnline(String uid) {
    final statusRef = _db.child('status/$uid');
    statusRef.set({'isOnline': true});
    statusRef.onDisconnect().set({'isOnline': false});
  }

  void _setUserOffline() {
    if (_currentUserId == null) return;
    _db.child('status/$_currentUserId').set({'isOnline': false});
  }

  String _getChatId(String uid1, String uid2) =>
      uid1.hashCode <= uid2.hashCode ? '$uid1-$uid2' : '$uid2-$uid1';

  Future<void> _openChat(String? friendId, String? friendName) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || friendId == null || friendName == null) return;

    final chatId = _getChatId(currentUserId, friendId);
    final chatRef = _db.child('chats/$chatId');

    final snapshot = await chatRef.get();
    final chatData = snapshot.value as Map<dynamic, dynamic>? ?? {};

    if (!snapshot.exists) {
      await chatRef.set({
        'participants': {currentUserId: true, friendId: true},
        'timestamp': ServerValue.timestamp,
        'lastMessage': '',
        'deletedFor': {},
        'blockedFor': {},
      });
    } else {
      final deletedFor =
          Map<String, dynamic>.from(chatData['deletedFor'] ?? {});
      if (deletedFor[currentUserId] == true) {
        deletedFor.remove(currentUserId);
        await chatRef.update({'deletedFor': deletedFor});
      }
    }

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

  Future<bool> _checkBlockStatus(String friendId, String chatId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return true;
    final blockedByMe = await _chatActions.isBlocked(
      currentUserId: currentUserId,
      chatId: chatId,
    );
    final blockedByFriend = await _chatActions.isBlocked(
      currentUserId: friendId,
      chatId: chatId,
    );
    return blockedByMe || blockedByFriend;
  }

  Future<void> _showUnblockDialog(
      String friendId, String chatId, String name) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("User Blocked"),
        content: Text("Do you want to unblock $name?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final currentUserId = _currentUserId;
              if (currentUserId != null) {
                await _chatActions.unblockUser(
                  currentUserId: currentUserId,
                  otherUserId: friendId,
                  chatId: chatId,
                );
                if (mounted) setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("Unblock"),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendAvatar(String? profilePic, String friendId,
      {double radius = 35, bool showOnlineDot = true}) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: (profilePic != null && profilePic.isNotEmpty)
              ? NetworkImage(profilePic)
              : null,
          child: (profilePic == null || profilePic.isEmpty)
              ? Icon(Icons.person, size: radius)
              : null,
        ),
        if (showOnlineDot)
          StreamBuilder<DatabaseEvent>(
            stream: _db.child('status/$friendId').onValue,
            builder: (context, snapshot) {
              bool isOnline = false;
              final value = snapshot.data?.snapshot.value;
              if (value is Map && value['isOnline'] != null) {
                isOnline = value['isOnline'] == true;
              } else if (value is bool) {
                isOnline = value;
              }
              if (!isOnline) return const SizedBox.shrink();
              return Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(date);
    if (diff.inDays == 1)
      return 'Yesterday ${DateFormat('hh:mm a').format(date)}';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final friendsRef =
        _firestore.collection('friends').doc(currentUserId).collection('list');
    final usersRef = _firestore.collection('users');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchText = value.toLowerCase()),
            ),
          ),
          // Friends horizontal list
          SizedBox(
            height: 130,
            child: StreamBuilder<QuerySnapshot>(
              stream: friendsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final friendIds = snapshot.data!.docs.map((e) => e.id).toList();
                if (friendIds.isEmpty)
                  return const Center(child: Text("No friends yet"));

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: friendIds.length,
                  itemBuilder: (context, i) {
                    final friendId = friendIds[i];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: usersRef.doc(friendId).snapshots(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists)
                          return const SizedBox.shrink();
                        final user =
                            userSnap.data!.data() as Map<String, dynamic>? ??
                                {};
                        final name =
                            "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                .trim();
                        final profilePic = user['profilePic'] ?? '';

                        if (_searchText.isNotEmpty &&
                            !name.toLowerCase().contains(_searchText)) {
                          return const SizedBox.shrink();
                        }

                        final chatId = _getChatId(currentUserId, friendId);

                        return FutureBuilder<bool>(
                          future: _checkBlockStatus(friendId, chatId),
                          builder: (context, blockedSnap) {
                            final isBlocked = blockedSnap.data ?? false;
                            return GestureDetector(
                              onTap: () {
                                if (isBlocked) {
                                  _showUnblockDialog(friendId, chatId, name);
                                } else {
                                  _openChat(friendId, name);
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      children: [
                                        _buildFriendAvatar(
                                            profilePic, friendId),
                                        if (isBlocked)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.block,
                                                  size: 12,
                                                  color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 70,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isBlocked
                                                ? Colors.red
                                                : Colors.black,
                                          ),
                                        ),
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
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Recent chats
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _db
                  .child('chats')
                  .orderByChild('participants/$currentUserId')
                  .equalTo(true)
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No recent chats"));
                }

                final rawData =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ??
                        {};
                final chats = <Map<String, dynamic>>[];

                rawData.forEach((chatId, chatDataRaw) {
                  final chatData = Map<String, dynamic>.from(chatDataRaw ?? {});
                  final deletedFor =
                      Map<String, dynamic>.from(chatData['deletedFor'] ?? {});
                  if (deletedFor[currentUserId] == true) return;

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
                if (chats.isEmpty)
                  return const Center(child: Text("No recent chats"));

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, i) {
                    final chat = chats[i];
                    final friendId = chat['participants'].keys.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '');
                    if (friendId.isEmpty) return const SizedBox.shrink();

                    final lastMsg = chat['lastMessage'].toString().isEmpty
                        ? "No messages yet"
                        : chat['lastMessage'];
                    final chatId = chat['chatId'];

                    return StreamBuilder<DocumentSnapshot>(
                      stream: usersRef.doc(friendId).snapshots(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists)
                          return const ListTile(title: Text("Unknown user"));
                        final user =
                            userSnap.data!.data() as Map<String, dynamic>? ??
                                {};
                        final name =
                            "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}"
                                .trim();
                        final profilePic = user['profilePic'] ?? '';

                        if (_searchText.isNotEmpty &&
                            !name.toLowerCase().contains(_searchText))
                          return const SizedBox.shrink();

                        return FutureBuilder<bool>(
                          future: _checkBlockStatus(friendId, chatId),
                          builder: (context, blockedSnap) {
                            final isBlocked = blockedSnap.data ?? false;
                            return ListTile(
                              leading: Stack(
                                children: [
                                  _buildFriendAvatar(profilePic, friendId,
                                      radius: 25, showOnlineDot: false),
                                  if (isBlocked)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.block,
                                            size: 12, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(name,
                                  style: TextStyle(
                                      color: isBlocked
                                          ? Colors.red
                                          : Colors.black)),
                              subtitle: Text(
                                lastMsg == "[Image]" ? "[Image]" : lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color:
                                        isBlocked ? Colors.red : Colors.grey),
                              ),
                              trailing: Text(
                                _formatTime(chat['timestamp']),
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isBlocked ? Colors.red : Colors.grey),
                              ),
                              onTap: () {
                                if (isBlocked) {
                                  _showUnblockDialog(friendId, chatId, name);
                                } else {
                                  _openChat(friendId, name);
                                }
                              },
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
