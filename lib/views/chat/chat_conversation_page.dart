import 'dart:async';
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

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Send text or image message
  Future<void> _sendMessage({List<String>? imageUrls}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && (imageUrls == null || imageUrls.isEmpty)) return;

    final chatRef = _dbRef.child('chats/${widget.chatId}');
    final msgRef = chatRef.child('messages').push();

    await msgRef.set({
      'senderId': widget.currentUserId,
      'text': text,
      'imageUrls': imageUrls ?? [],
      'timestamp': ServerValue.timestamp,
    });

    // Update chat metadata
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Stream messages in real-time
  Stream<List<Map<String, dynamic>>> _messagesStream() {
    final chatRef = _dbRef.child('chats/${widget.chatId}');
    return chatRef.onValue.map((event) {
      final chatData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (chatData == null) return [];

      final deletedFor = chatData['deletedFor'] as Map<dynamic, dynamic>? ?? {};
      if (deletedFor[widget.currentUserId] == true) return [];

      final messagesData = chatData['messages'] as Map<dynamic, dynamic>? ?? {};
      final messages = messagesData.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value as Map);
        map['key'] = e.key;
        return map;
      }).toList();

      messages
          .sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
      return messages;
    });
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == widget.currentUserId;
                    final text = msg['text'] ?? '';
                    final imageUrls =
                        (msg['imageUrls'] as List?)?.cast<String>() ?? [];
                    final timestamp = msg['timestamp'] is int
                        ? msg['timestamp'] as int
                        : null;

                    return Container(
                      margin: EdgeInsets.only(
                        left: isMe ? 50 : 10,
                        right: isMe ? 10 : 50,
                        top: 4,
                        bottom: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(text,
                                  style: const TextStyle(fontSize: 16)),
                            ),
                          if (imageUrls.isNotEmpty)
                            Column(
                              children: imageUrls
                                  .map((url) => Padding(
                                        padding:
                                            const EdgeInsets.only(top: 5.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            width: 200,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatTime(timestamp),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(child: _buildMessageInput()),
        ],
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
              icon: const Icon(Icons.photo_outlined), onPressed: _pickImages),
          IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: _takePhoto),
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
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
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
