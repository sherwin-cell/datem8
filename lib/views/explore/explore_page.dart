import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/views/post/new_post_page.dart';
import 'comments_section.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExplorePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const ExplorePage({super.key, required this.cloudinaryService});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _refreshPosts() async => setState(() {});

  Future<Map<String, String>> _getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return {'name': 'Unknown', 'avatar': ''};
      final data = doc.data()!;
      return {
        'name': data['name'] ?? 'Unknown',
        'avatar': data['profilePic'] ?? '',
      };
    } catch (_) {
      return {'name': 'Unknown', 'avatar': ''};
    }
  }

  Future<void> _updateReaction(String postId, String emoji) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(postRef);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      // Toggle reaction
      if (reactions[user.uid] == emoji) {
        reactions.remove(user.uid);
      } else {
        reactions[user.uid] = emoji;
      }

      transaction.update(postRef, {'reactions': reactions});
    });
  }

  Future<String?> _showEmojiPicker(BuildContext context) async {
    final emojis = ['❤️', '😆', '😮', '😢', '😡'];
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis
              .map((emoji) => GestureDetector(
                    onTap: () => Navigator.pop(context, emoji),
                    child: Text(
                      emoji,
                      style: GoogleFonts.notoColorEmoji(fontSize: 36),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _openComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommentsSection(postId: postId),
    );
  }

  void _openNewPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewPostPage(cloudinaryService: widget.cloudinaryService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsRef =
        _firestore.collection('posts').orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 229, 239),
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: const Color.fromARGB(255, 106, 105, 105),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: StreamBuilder<QuerySnapshot>(
          stream: postsRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return const SizedBox();

                  return FutureBuilder<Map<String, String>>(
                    future: _getUserInfo(uid),
                    builder: (context, snap) {
                      final avatar = snap.data?['avatar'] ?? '';
                      return GestureDetector(
                        onTap: _openNewPost,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                                child: avatar.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Share something you're grateful for...",
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                final postDoc = posts[index - 1];
                final postData = postDoc.data() as Map<String, dynamic>;
                final caption = postData['caption'] ?? '';
                final userId = postData['userId'] ?? '';
                final createdAt = (postData['createdAt'] is Timestamp)
                    ? (postData['createdAt'] as Timestamp).toDate()
                    : DateTime.now();

                final images = postData['imageUrls'] != null
                    ? List<String>.from(postData['imageUrls'])
                    : postData['imageUrl'] != null
                        ? [postData['imageUrl']]
                        : [];

                return FutureBuilder<Map<String, String>>(
                  future: _getUserInfo(userId),
                  builder: (context, snap) {
                    final user = snap.data ?? {'name': 'Unknown', 'avatar': ''};

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 👤 User info
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: user['avatar']!.isNotEmpty
                                  ? NetworkImage(user['avatar']!)
                                  : null,
                              child: user['avatar']!.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user['name']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              DateFormat.yMMMd().add_jm().format(createdAt),
                            ),
                          ),

                          // 🖼️ Post image
                          if (images.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 250,
                                child: PageView.builder(
                                  itemCount: images.length,
                                  itemBuilder: (context, i) => Image.network(
                                    images[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),

                          // ✍ Caption
                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(caption,
                                  style: const TextStyle(fontSize: 16)),
                            ),

                          // ❤️ Reactions and comments
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: postDoc.reference.snapshots(),
                              builder: (context, snap) {
                                if (!snap.hasData) return const SizedBox();

                                final post =
                                    snap.data!.data() as Map<String, dynamic>;
                                final reactions = Map<String, dynamic>.from(
                                    post['reactions'] ?? {});
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                final userReaction = reactions[uid] ?? '';

                                final counts = <String, int>{};
                                for (var emoji in reactions.values) {
                                  counts[emoji] = (counts[emoji] ?? 0) + 1;
                                }

                                return StreamBuilder<QuerySnapshot>(
                                  stream: postDoc.reference
                                      .collection('comments')
                                      .snapshots(),
                                  builder: (context, commentSnap) {
                                    final commentCount =
                                        commentSnap.data?.docs.length ?? 0;

                                    return Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _updateReaction(postDoc.id, '❤️'),
                                          onLongPress: () async {
                                            final emoji =
                                                await _showEmojiPicker(context);
                                            if (emoji != null) {
                                              _updateReaction(
                                                  postDoc.id, emoji);
                                            }
                                          },
                                          child: Text(
                                            userReaction.isNotEmpty
                                                ? userReaction
                                                : '❤️',
                                            style: GoogleFonts.notoColorEmoji(
                                                fontSize: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (counts.isNotEmpty)
                                          Row(
                                            children: counts.entries
                                                .map((e) => Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4),
                                                      child: Text(
                                                        "${e.key}${e.value}",
                                                        style: GoogleFonts
                                                            .notoColorEmoji(
                                                                fontSize: 18),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.comment_outlined),
                                          onPressed: () =>
                                              _openComments(postDoc.id),
                                        ),
                                        Text("$commentCount"),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
