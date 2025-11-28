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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ================= Block Status =================
  Future<void> _checkBlockStatus() async {
    try {
      final blocked = await _chatActions.isBlocked(
        currentUserId: widget.currentUserId,
        chatId: widget.chatId,
      );
      if (mounted) setState(() => _isBlocked = blocked);
    } catch (_) {}
  }

  // ================= Send Messages =================
  Future<void> _sendMessage({List<String>? imageUrls}) async {
    if (_isBlocked) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && (imageUrls == null || imageUrls.isEmpty)) return;

    final chatRef = _dbRef.child('chats/${widget.chatId}');
    final msgRef = chatRef.child('messages').push();

    final localTimestamp = DateTime.now().millisecondsSinceEpoch;

    await msgRef.set({
      'senderId': widget.currentUserId,
      'type': 'text',
      'text': text,
      'imageUrls': imageUrls ?? [],
      'timestamp': ServerValue.timestamp, // server timestamp
      'localTimestamp': localTimestamp, // local fallback
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

  Future<void> _sendCallMessage(
      {required bool isVideo, required int duration}) async {
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

  Future<void> _startCall({required bool isVideo}) async {
    if (_isBlocked) return;

    // Push CallPage and wait for duration
    final duration = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          callID: widget.chatId,
          currentUserID: widget.currentUserId,
          otherUserID: widget.otherUserId,
          otherUserName: widget.otherUserName,
          isVideoCall: isVideo,
          cloudinaryService: widget.cloudinaryService,
        ),
      ),
    );

    // Send call message if duration is returned
    if (duration != null) {
      await _sendCallMessage(isVideo: isVideo, duration: duration);
    }
  }

  // ================= Messages Stream =================
  Stream<List<Map<String, dynamic>>> _messagesStream() {
    final messagesRef = _dbRef.child('chats/${widget.chatId}/messages');
    return messagesRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final messages = data.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value as Map? ?? {});
        map['key'] = e.key;

        // Ensure timestamp is an int, fallback to 0 if missing
        if (map['timestamp'] is! int) {
          map['timestamp'] = 0;
        }
        return map;
      }).toList();

      // Sort messages by timestamp reliably
      messages.sort((a, b) {
        final tsA = a['timestamp'] as int;
        final tsB = b['timestamp'] as int;
        return tsA.compareTo(tsB);
      });

      return messages;
    });
  }

  // ================= Group Messages =================
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

  // ================= Formatting =================
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

  // ================= Scroll =================
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  // ================= Image Handling =================
  Future<void> _pickImages() async {
    if (_isBlocked) return;
    try {
      final urls = await widget.cloudinaryService.pickAndUploadMultipleImages();
      if (urls.isNotEmpty) await _sendMessage(imageUrls: urls);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to send images: $e")));
    }
  }

  Future<void> _takePhoto() async {
    if (_isBlocked) return;
    try {
      final url = await widget.cloudinaryService.takePhotoAndUpload();
      if (url != null) await _sendMessage(imageUrls: [url]);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to send photo: $e")));
    }
  }

  // ================= Build =================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        title: Text(widget.otherUserName, style: theme.textTheme.titleMedium),
        actions: [
          IconButton(
              icon: const Icon(Icons.call),
              onPressed: () => _startCall(isVideo: false)),
          IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () => _startCall(isVideo: true)),
          _buildPopupMenu(theme),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(theme)),
          SafeArea(child: _buildMessageInput(theme)),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  color: theme.colorScheme.secondary));
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return Center(
              child:
                  Text("No messages yet.", style: theme.textTheme.bodySmall));
        }

        final groupedMessages = _groupMessages(messages);

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groupedMessages.length,
          itemBuilder: (context, index) {
            // reversed index to show newest at bottom
            final group = groupedMessages[groupedMessages.length - 1 - index];
            final isMe = group[0]['senderId'] == widget.currentUserId;

            return Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Text(_formatTime(group[0]['timestamp']),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  ),
                ),
                ...group.map((msg) => _buildMessageTile(msg, isMe, theme)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageTile(
      Map<String, dynamic> msg, bool isMe, ThemeData theme) {
    final type = msg['type'] ?? 'text';
    final text = msg['text'] ?? '';
    final imageUrls = (msg['imageUrls'] as List?)?.cast<String>() ?? [];

    if (type == 'call') return _buildCallTile(msg, isMe, theme);

    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isMe
        ? (isDark ? Colors.blue[700] : Colors.blue[100])
        : (isDark ? Colors.grey[800] : Colors.grey[300]);
    final textColor = isMe ? Colors.white : Colors.black87;

    return GestureDetector(
      onLongPress: isMe
          ? () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: theme.dialogBackgroundColor,
                  title: Text('Unsend Message?',
                      style: theme.textTheme.titleMedium),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child:
                            Text('Cancel', style: theme.textTheme.bodyMedium)),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child:
                            Text('Unsend', style: theme.textTheme.bodyMedium)),
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
                    color: bgColor, borderRadius: BorderRadius.circular(20)),
                child: Text(text,
                    style: TextStyle(fontSize: 16, color: textColor)),
              ),
            if (imageUrls.isNotEmpty)
              Column(
                children: imageUrls
                    .map((url) => Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(url,
                                fit: BoxFit.cover, width: 200),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTile(Map<String, dynamic> msg, bool isMe, ThemeData theme) {
    final isVideo = msg['isVideo'] ?? true;
    final duration = msg['duration'] ?? 0;
    final isMissed = msg['missed'] ?? false;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isMe
        ? (isDark ? Colors.blue[700] : Colors.blue[100])
        : (isDark ? Colors.grey[800] : Colors.grey[300]);
    final textColor = isMe ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () => _startCall(isVideo: isVideo),
      child: Container(
        margin: EdgeInsets.only(
            left: isMe ? 50 : 10, right: isMe ? 10 : 50, top: 4, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVideo
                  ? (isMissed ? "Missed Video Call" : "Video Call")
                  : (isMissed ? "Missed Voice Call" : "Voice Call"),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            if (!isMissed) SizedBox(height: 4),
            if (!isMissed)
              Text(_formatDuration(duration),
                  style: TextStyle(color: textColor)),
            SizedBox(height: 4),
            Text("Call Again",
                style: TextStyle(color: theme.colorScheme.secondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: theme.appBarTheme.backgroundColor,
      child: Row(
        children: [
          IconButton(
              icon: Icon(Icons.photo_outlined, color: theme.iconTheme.color),
              onPressed: _isBlocked ? null : _pickImages),
          IconButton(
              icon:
                  Icon(Icons.camera_alt_outlined, color: theme.iconTheme.color),
              onPressed: _isBlocked ? null : _takePhoto),
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isBlocked,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: _isBlocked
                    ? "You have blocked this user"
                    : "Type a message...",
                hintStyle: theme.textTheme.bodySmall,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none),
                fillColor: theme.cardColor,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.send),
              color: theme.colorScheme.secondary,
              onPressed: _isBlocked ? null : _sendMessage),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      color: theme.cardColor,
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
                chatId: widget.chatId);
            if (mounted) setState(() => _isBlocked = true);
          } else {
            await _chatActions.unblockUser(
                currentUserId: widget.currentUserId,
                otherUserId: widget.otherUserId,
                chatId: widget.chatId);
            if (mounted) setState(() => _isBlocked = false);
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'delete',
            child: Text('Delete Conversation',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
        PopupMenuItem(
            value: 'block',
            child: Text(_isBlocked ? 'Unblock User' : 'Block User',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
      ],
    );
  }
}
