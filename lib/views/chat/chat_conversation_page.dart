import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/helper/utils/blocked_user_service.dart';
import 'package:datem8/views/profile/other_profile_page.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final BlockedUserService _blockedService = BlockedUserService();

  final Set<String> _tappedMessages = {};
  final Map<String, String> _reactions = {};
  final List<String> _reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "😡"];

  bool _isBlocked = false;
  bool _currentUserBlockedOther = false;

  @override
  void initState() {
    super.initState();
    _checkBlockedStatus();
  }

  Future<void> _checkBlockedStatus() async {
    final blocked = await _blockedService.isBlocked(
        widget.currentUserId, widget.otherUserId);
    final currentUserBlockedOther = await _blockedService.isUserBlocked(
        widget.currentUserId, widget.otherUserId);

    if (mounted) {
      setState(() {
        _isBlocked = blocked;
        _currentUserBlockedOther = currentUserBlockedOther;
      });
    }
  }

  Future<void> _sendMessage({List<String>? imageUrls}) async {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("Messaging is disabled because one of you blocked the other."),
      ));
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty && (imageUrls == null || imageUrls.isEmpty)) return;

    try {
      final chatRef = _dbRef.child('chats/${widget.chatId}');
      await chatRef.update({
        'participants': {widget.currentUserId: true, widget.otherUserId: true},
        'timestamp': ServerValue.timestamp,
        'lastMessage': text.isNotEmpty ? text : "[Image]",
        'lastMessageSenderId': widget.currentUserId,
      });

      final msgRef = chatRef.child('messages').push();
      await msgRef.set({
        'senderId': widget.currentUserId,
        'text': text,
        'imageUrls': imageUrls ?? [],
        'timestamp': ServerValue.timestamp,
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to send message: $e")));
    }
  }

  Future<void> _unsendMessage(String msgKey) async {
    try {
      await _dbRef.child('chats/${widget.chatId}/messages/$msgKey').remove();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to unsend message: $e")));
    }
  }

  Future<void> _reactToMessage(String msgKey, String emoji) async {
    final msgRef =
        _dbRef.child('chats/${widget.chatId}/messages/$msgKey/reaction');
    await msgRef.set({'userId': widget.currentUserId, 'emoji': emoji});
    setState(() => _reactions[msgKey] = emoji);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Stream<List<Map<String, dynamic>>> _messagesStream() {
    final chatRef = _dbRef.child('chats/${widget.chatId}/messages');
    return chatRef.orderByChild('timestamp').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final msgs = data.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value as Map);
        map['key'] = e.key;
        return map;
      }).toList();
      msgs.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
      return msgs;
    });
  }

  Future<void> _pickImages() async {
    try {
      final imageUrls =
          await widget.cloudinaryService.pickAndUploadMultipleImages();
      if (imageUrls.isNotEmpty) await _sendMessage(imageUrls: imageUrls);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to send images: $e")));
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imageUrl = await widget.cloudinaryService.takePhotoAndUpload();
      if (imageUrl != null) await _sendMessage(imageUrls: [imageUrl]);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to send photo: $e")));
    }
  }

  Future<void> _deleteConversation() async {
    try {
      await _dbRef.child('chats/${widget.chatId}').remove();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete conversation: $e")));
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('MMM dd, yyyy hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['senderId'] == widget.currentUserId;
    final msgKey = msg['key'];
    final isTapped = _tappedMessages.contains(msgKey);
    final reactionEmoji = msg['reaction']?['emoji'] ?? _reactions[msgKey];
    final List<dynamic> imageUrls =
        (msg['imageUrls'] ?? (msg['imageUrl'] != null ? [msg['imageUrl']] : []))
            .cast<String>();
    final hasImages = imageUrls.isNotEmpty;
    final hasText = (msg['text'] ?? "").isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => isTapped
          ? _tappedMessages.remove(msgKey)
          : _tappedMessages.add(msgKey)),
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (_) =>
              _MessageActionSheet(isMe: isMe, emojis: _reactionEmojis),
        );
        if (action != null) {
          if (action == 'delete')
            _unsendMessage(msgKey);
          else if (_reactionEmojis.contains(action))
            _reactToMessage(msgKey, action);
        }
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (hasImages)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrls[i],
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.width * 0.4,
                    ),
                  ),
                ),
              if (hasText)
                Container(
                  margin: EdgeInsets.only(top: hasImages ? 6 : 0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[300] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(msg['text'],
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15)),
                ),
              if (reactionEmoji != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child:
                      Text(reactionEmoji, style: const TextStyle(fontSize: 18)),
                ),
              if (isTapped)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(_formatTime(msg['timestamp']),
                      style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black54)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    if (_isBlocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            "Messaging is disabled because one of you blocked the other.",
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.photo_library),
              color: Colors.grey[700],
              onPressed: _pickImages),
          IconButton(
              icon: const Icon(Icons.camera_alt),
              color: Colors.grey[700],
              onPressed: _takePhoto),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(30)),
              child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                      hintText: "Type a message...", border: InputBorder.none)),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.send),
              color: Colors.blue,
              onPressed: () => _sendMessage()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'view_profile':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OtherUserProfilePage(
                              userId: widget.otherUserId,
                              userName: widget.otherUserName,
                              cloudinaryService: widget.cloudinaryService,
                              avatarUrl: "")));
                  break;
                case 'block':
                  await _blockedService.blockUser(
                      widget.currentUserId, widget.otherUserId);
                  break;
                case 'unblock':
                  await _blockedService.unblockUser(
                      widget.currentUserId, widget.otherUserId);
                  break;
                case 'delete':
                  await _deleteConversation();
                  break;
              }
              await _checkBlockedStatus();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'view_profile', child: Text('View Profile')),
              _currentUserBlockedOther
                  ? const PopupMenuItem(
                      value: 'unblock', child: Text('Unblock User'))
                  : const PopupMenuItem(
                      value: 'block', child: Text('Block User')),
              const PopupMenuItem(
                  value: 'delete', child: Text('Delete Conversation')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(messages[index]));
              },
            ),
          ),
          const Divider(height: 1),
          _buildInputField(),
        ],
      ),
    );
  }
}

class _MessageActionSheet extends StatelessWidget {
  final bool isMe;
  final List<String> emojis;
  const _MessageActionSheet({required this.isMe, required this.emojis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: emojis
                .map((emoji) => GestureDetector(
                      onTap: () => Navigator.of(context).pop(emoji),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ))
                .toList(),
          ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Unsend"),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
        ],
      ),
    );
  }
}
