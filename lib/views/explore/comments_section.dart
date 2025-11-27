import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommentsSection extends StatefulWidget {
  final String postId;
  const CommentsSection({super.key, required this.postId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();
  String? _postOwnerId;

  @override
  void initState() {
    super.initState();
    _fetchPostOwner();
  }

  Future<void> _fetchPostOwner() async {
    final doc = await _firestore.collection('posts').doc(widget.postId).get();
    if (doc.exists) {
      setState(() => _postOwnerId = doc['userId'] as String?);
    }
  }

  Future<void> _addComment() async {
    final user = _auth.currentUser;
    final text = _commentController.text.trim();
    if (user == null || text.isEmpty) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'name':
          "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim(),
      'profilePic': userData['profilePic'] ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  Future<void> _deleteComment(String commentId, String commentUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (user.uid == commentUserId || user.uid == _postOwnerId) {
      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    }
  }

  Widget _buildCommentTile(String commentId, Map<String, dynamic> comment) {
    final name = comment['name'] ?? 'Unknown';
    final avatar = comment['profilePic'] ?? '';
    final text = comment['text'] ?? '';
    final timestamp = comment['createdAt'] as Timestamp?;
    final time = timestamp != null
        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
        : '';

    final isCommentOwner = comment['userId'] == _auth.currentUser?.uid;
    final isPostOwner = _auth.currentUser?.uid == _postOwnerId;
    final canDelete = isCommentOwner || isPostOwner;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(text),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: () => _deleteComment(commentId, comment['userId']),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text("Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty)
                    return const Center(child: Text("No comments yet."));

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final doc = comments[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildCommentTile(doc.id, data);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 8),
            Padding(
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _addComment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
