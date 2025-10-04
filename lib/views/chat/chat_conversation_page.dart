import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:datem8/services/cloudinary_service.dart';

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

  final Set<String> _tappedMessages = {};
  final Map<String, String> _reactions = {};
  final List<String> _reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "😡"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // ---------------- Messaging ----------------
  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    try {
      final chatRef = _dbRef.child('chats/${widget.chatId}');
      await chatRef.update({
        'participants': {
          widget.currentUserId: true,
          widget.otherUserId: true,
        },
        'timestamp': ServerValue.timestamp,
        'lastMessage': text.isNotEmpty ? text : "[Image]",
      });

      final msgRef = chatRef.child('messages').push();
      await msgRef.set({
        'senderId': widget.currentUserId,
        'text': text,
        'imageUrl': imageUrl ?? "",
        'timestamp': ServerValue.timestamp,
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send message: $e")));
      }
    }
  }

  Future<void> _unsendMessage(String msgKey) async {
    try {
      await _dbRef.child('chats/${widget.chatId}/messages/$msgKey').remove();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to unsend message: $e")));
      }
    }
  }

  Future<void> _reactToMessage(String msgKey, String emoji) async {
    final msgRef =
        _dbRef.child('chats/${widget.chatId}/messages/$msgKey/reaction');
    await msgRef.set({'userId': widget.currentUserId, 'emoji': emoji});

    setState(() => _reactions[msgKey] = emoji);
  }

  // ---------------- Helpers ----------------
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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

  Future<void> _pickImage() async {
    try {
      final imageUrl = await widget.cloudinaryService.pickAndUploadImage();
      if (imageUrl != null) await _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to send image: $e")));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imageUrl = await widget.cloudinaryService.takePhotoAndUpload();
      if (imageUrl != null) await _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to send photo: $e")));
      }
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  // ---------------- Widgets ----------------
  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['senderId'] == widget.currentUserId;
    final msgKey = msg['key'];
    final isTapped = _tappedMessages.contains(msgKey);
    final reactionEmoji = msg['reaction']?['emoji'] ?? _reactions[msgKey];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isTapped)
            _tappedMessages.remove(msgKey);
          else
            _tappedMessages.add(msgKey);
        });
      },
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _MessageActionSheet(
            isMe: isMe,
            emojis: _reactionEmojis,
          ),
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
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[300] : Colors.grey[300],
            borderRadius: BorderRadius.circular(30),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((msg['imageUrl'] ?? "").isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      msg['imageUrl'],
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.width * 0.6,
                      fit: BoxFit.cover,
                    ),
                  ),
                if ((msg['text'] ?? "").isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87),
                    ),
                  ),
                if (reactionEmoji != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(reactionEmoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                if (isTapped)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      _formatTime(msg['timestamp']),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.photo),
              color: Colors.green,
              onPressed: _pickImage),
          IconButton(
              icon: const Icon(Icons.camera_alt),
              color: Colors.orange,
              onPressed: _takePhoto),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                ),
              ),
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
      appBar: AppBar(title: Text(widget.otherUserName)),
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
                      _buildMessage(messages[index]),
                );
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

// Bottom sheet for reactions + delete
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
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(emoji),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              );
            }).toList(),
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
