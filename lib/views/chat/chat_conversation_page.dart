import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'call_page.dart';
import 'chat_actions.dart';

class ChatConversationPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final CloudinaryService cloudinaryService;

  const ChatConversationPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.cloudinaryService,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _dbRef = FirebaseDatabase.instance.ref();
  final _chatActions = ChatActions();

  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkBlockStatus() async {
    try {
      final blocked = await _chatActions.isBlocked(
        currentUserId: widget.currentUserId,
        chatId: widget.chatId,
      );
      if (mounted) setState(() => _isBlocked = blocked);
    } catch (_) {}
  }

  // ---------------- Messaging ----------------

  Future<void> _sendMessage({List<String>? imageUrls}) async {
    if (_isBlocked) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && (imageUrls == null || imageUrls.isEmpty)) return;

    final chatRef = _dbRef.child('chats/${widget.chatId}');
    final msgRef = chatRef.child('messages').push();

    await msgRef.set({
      'senderId': widget.currentUserId,
      'type': 'text',
      'text': text,
      'imageUrls': imageUrls ?? [],
      'timestamp': ServerValue.timestamp,
    });

    await chatRef.update({
      'participants': {
        widget.currentUserId: true,
        widget.otherUserId: true,
      },
      'timestamp': ServerValue.timestamp,
      'lastMessage': text.isNotEmpty ? text : "[Image]",
      'lastMessageSenderId': widget.currentUserId,
    });

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendCallMessage({
    required bool isVideo,
    required int duration,
  }) async {
    if (_isBlocked) return;

    final chatRef = _dbRef.child('chats/${widget.chatId}');
    final msgRef = chatRef.child('messages').push();

    await msgRef.set({
      'senderId': widget.currentUserId,
      'type': 'call',
      'isVideo': isVideo,
      'duration': duration,
      'missed': duration == 0,
      'timestamp': ServerValue.timestamp,
    });

    await chatRef.update({
      'participants': {
        widget.currentUserId: true,
        widget.otherUserId: true,
      },
      'timestamp': ServerValue.timestamp,
      'lastMessage': isVideo
          ? (duration == 0 ? "[Missed Video Call]" : "[Video Call]")
          : (duration == 0 ? "[Missed Voice Call]" : "[Voice Call]"),
      'lastMessageSenderId': widget.currentUserId,
    });
  }

  // ---------------- Scrolling ----------------

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.position.minScrollExtent;

    if (animated) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(offset);
    }
  }

  // ---------------- Messages Stream ----------------

  Stream<List<Map<String, dynamic>>> _messagesStream() {
    final chatRef = _dbRef.child('chats/${widget.chatId}');

    return chatRef.onValue.map((event) {
      final chatData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (chatData == null) return [];

      final deletedFor = chatData['deletedFor'] as Map<dynamic, dynamic>? ?? {};
      if (deletedFor[widget.currentUserId] == true) return [];

      final blockedFor = chatData['blockedFor'] as Map<dynamic, dynamic>? ?? {};
      if (blockedFor[widget.currentUserId] == true) return [];

      final messagesData = chatData['messages'] as Map<dynamic, dynamic>? ?? {};
      final messages = messagesData.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value as Map? ?? {});
        map['key'] = e.key;
        return map;
      }).toList();

      messages
          .sort((a, b) => (a['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      return messages;
    });
  }

  // ---------------- Call Handling ----------------

  void _startCall({required bool isVideo}) async {
    if (_isBlocked) return;

    final duration = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          callID: widget.chatId,
          userID: widget.currentUserId,
          userName: widget.otherUserName,
          isVideoCall: isVideo,
        ),
      ),
    );

    if (duration != null) {
      await _sendCallMessage(isVideo: isVideo, duration: duration);
    }
  }

  // ---------------- Helpers ----------------

  String _formatTime(int? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs mins";
  }

  List<List<Map<String, dynamic>>> _groupMessages(
      List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return [];
    List<List<Map<String, dynamic>>> grouped = [];
    List<Map<String, dynamic>> currentGroup = [messages[0]];

    for (int i = 1; i < messages.length; i++) {
      if (messages[i]['senderId'] == messages[i - 1]['senderId'] &&
          messages[i]['type'] == 'text' &&
          messages[i - 1]['type'] == 'text') {
        currentGroup.add(messages[i]);
      } else {
        grouped.add(currentGroup);
        currentGroup = [messages[i]];
      }
    }

    grouped.add(currentGroup);
    return grouped;
  }

  // ---------------- Image Upload ----------------

  Future<void> _pickImages() async {
    if (_isBlocked) return;

    try {
      final imageUrls =
          await widget.cloudinaryService.pickAndUploadMultipleImages();
      if (imageUrls.isNotEmpty) await _sendMessage(imageUrls: imageUrls);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to send images: $e")));
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_isBlocked) return;

    try {
      final imageUrl = await widget.cloudinaryService.takePhotoAndUpload();
      if (imageUrl != null) await _sendMessage(imageUrls: [imageUrl]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to send photo: $e")));
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
              icon: const Icon(Icons.call),
              onPressed: () => _startCall(isVideo: false)),
          IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () => _startCall(isVideo: true)),
          _buildPopupMenu(),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          SafeArea(child: _buildMessageInput()),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'delete') {
          await _chatActions.deleteConversation(
            chatId: widget.chatId,
            currentUserId: widget.currentUserId,
            participantIds: [widget.currentUserId, widget.otherUserId],
          );
          if (mounted) Navigator.pop(context);
        } else if (value == 'block') {
          if (!_isBlocked) {
            await _chatActions.blockUser(
              currentUserId: widget.currentUserId,
              otherUserId: widget.otherUserId,
              chatId: widget.chatId,
            );
            if (mounted) setState(() => _isBlocked = true);
          } else {
            await _chatActions.unblockUser(
              currentUserId: widget.currentUserId,
              otherUserId: widget.otherUserId,
              chatId: widget.chatId,
            );
            if (mounted) setState(() => _isBlocked = false);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'delete', child: Text('Delete Conversation')),
        PopupMenuItem(
            value: 'block',
            child: Text(_isBlocked ? 'Unblock User' : 'Block User')),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final messages = snapshot.data!;
        if (messages.isEmpty)
          return const Center(child: Text("No messages yet."));

        final groupedMessages = _groupMessages(messages);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groupedMessages.length,
          itemBuilder: (context, index) {
            final group = groupedMessages[groupedMessages.length - 1 - index];
            final isMe = group[0]['senderId'] == widget.currentUserId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Text(_formatTime(group[0]['timestamp']),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),
                ...group.map((msg) => _buildMessageTile(msg, isMe)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> msg, bool isMe) {
    final type = msg['type'] ?? 'text';
    final text = msg['text'] ?? '';
    final imageUrls = (msg['imageUrls'] as List?)?.cast<String>() ?? [];

    if (type == 'call') return _buildCallTile(msg, isMe);

    return GestureDetector(
      onLongPress: isMe
          ? () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Unsend Message?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Unsend')),
                  ],
                ),
              );

              if (confirm == true) {
                await _chatActions.unsendMessage(
                    chatId: widget.chatId, messageKey: msg['key']);
              }
            }
          : null,
      child: Container(
        margin: EdgeInsets.only(
            left: isMe ? 50 : 10, right: isMe ? 10 : 50, top: 4, bottom: 4),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (text.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(text, style: const TextStyle(fontSize: 16)),
              ),
            if (imageUrls.isNotEmpty)
              Column(
                children: imageUrls
                    .map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child:
                              Image.network(url, fit: BoxFit.cover, width: 200),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTile(Map<String, dynamic> msg, bool isMe) {
    final isVideo = msg['isVideo'] ?? true;
    final duration = msg['duration'] ?? 0;
    final isMissed = msg['missed'] ?? false;

    return GestureDetector(
      onTap: () => _startCall(isVideo: isVideo),
      child: Container(
        margin: EdgeInsets.only(
            left: isMe ? 50 : 10, right: isMe ? 10 : 50, top: 4, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVideo
                  ? (isMissed ? "Missed Video Call" : "Video Call")
                  : (isMissed ? "Missed Voice Call" : "Voice Call"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!isMissed) ...[
              const SizedBox(height: 4),
              Text(_formatDuration(duration)),
            ],
            const SizedBox(height: 4),
            const Text("Call Again", style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.photo_outlined),
              onPressed: _isBlocked ? null : _pickImages),
          IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: _isBlocked ? null : _takePhoto),
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isBlocked,
              decoration: InputDecoration(
                hintText: _isBlocked
                    ? "You have blocked this user"
                    : "Type a message...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none),
                fillColor: Colors.grey.shade200,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.send),
              color: Colors.blueAccent,
              onPressed: _isBlocked ? null : _sendMessage),
        ],
      ),
    );
  }
}
