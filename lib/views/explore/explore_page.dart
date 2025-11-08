import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/profile_modal.dart';
import 'comments_section.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:datem8/views/post/new_post_page.dart';

class ExplorePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const ExplorePage({super.key, required this.cloudinaryService});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _firestore = FirebaseFirestore.instance;
  final Map<String, int> _currentPages = {};

  Future<void> _refreshPosts() async => setState(() {});

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return {'name': 'Unknown', 'avatar': ''};
      final data = doc.data()!;
      return {
        'name': data['name'] ?? 'Unknown',
        'avatar': data['profilePic'] ?? '',
        'email': data['email'] ?? '',
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'profilePic': data['profilePic'] ?? '',
        'uid': data['uid'] ?? userId,
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

      if (reactions[user.uid] == emoji) {
        reactions.remove(user.uid);
      } else {
        reactions[user.uid] = emoji;
      }

      transaction.update(postRef, {'reactions': reactions});
    });
  }

  Future<String?> _showEmojiPicker(BuildContext context) async {
    const emojis = ['❤️', '😆', '😮', '😢', '😡'];
    return showModalBottomSheet<String>(
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
              .map(
                (emoji) => GestureDetector(
                  onTap: () => Navigator.pop(context, emoji),
                  child: Text(emoji,
                      style: GoogleFonts.notoColorEmoji(fontSize: 36)),
                ),
              )
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

  void _showProfileModal(BuildContext context, Map<String, dynamic> userData) {
    showProfileModal(
      context,
      userData: userData,
      cloudinaryService: widget.cloudinaryService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsRef =
        _firestore.collection('posts').orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F7),
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: const Color(0xFF6A6969),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: StreamBuilder<QuerySnapshot>(
          stream: postsRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final posts = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postDoc = posts[index];
                final postData = postDoc.data() as Map<String, dynamic>;
                final caption = postData['caption'] ?? '';
                final userId = postData['userId'] ?? '';
                final createdAt = (postData['createdAt'] is Timestamp)
                    ? (postData['createdAt'] as Timestamp).toDate()
                    : DateTime.now();

                final images = postData['imageUrls'] != null
                    ? List<String>.from((postData['imageUrls'] as List)
                        .map((e) => e.toString()))
                    : postData['imageUrl'] != null
                        ? [postData['imageUrl'].toString()]
                        : [];

                return FutureBuilder<Map<String, dynamic>>(
                  future: _getUserInfo(userId),
                  builder: (context, snap) {
                    final user = snap.data ??
                        {'name': 'Unknown', 'avatar': '', 'uid': userId};
                    final currentPage = _currentPages[postDoc.id] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            leading: GestureDetector(
                              onTap: () => _showProfileModal(context, user),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage: user['avatar']!.isNotEmpty
                                    ? NetworkImage(user['avatar']!)
                                    : null,
                                child: user['avatar']!.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.grey)
                                    : null,
                              ),
                            ),
                            title: GestureDetector(
                              onTap: () => _showProfileModal(context, user),
                              child: Text(user['name']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ),
                            subtitle: Text(
                              DateFormat.yMMMd().add_jm().format(createdAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ),
                          // Post Images
                          if (images.isNotEmpty)
                            Column(
                              children: [
                                SizedBox(
                                  height: 260,
                                  child: PageView.builder(
                                    itemCount: images.length,
                                    onPageChanged: (page) => setState(
                                        () => _currentPages[postDoc.id] = page),
                                    itemBuilder: (context, i) => Image.network(
                                      images[i],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                if (images.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children:
                                          List.generate(images.length, (i) {
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          height: 8,
                                          width: i == currentPage ? 20 : 8,
                                          decoration: BoxDecoration(
                                            color: i == currentPage
                                                ? const Color(0xFF6A1B9A)
                                                : Colors.grey[400],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          // Caption
                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Text(caption,
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.5)),
                            ),
                          // Reactions & Comments
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _updateReaction(
                                                postDoc.id, '❤️'),
                                            onLongPress: () async {
                                              final emoji =
                                                  await _showEmojiPicker(
                                                      context);
                                              if (emoji != null)
                                                _updateReaction(
                                                    postDoc.id, emoji);
                                            },
                                            child: Text(
                                              userReaction.isNotEmpty
                                                  ? userReaction
                                                  : '❤️',
                                              style: GoogleFonts.notoColorEmoji(
                                                  fontSize: 22),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (counts.isNotEmpty)
                                            Row(
                                              children: counts.entries
                                                  .map(
                                                    (e) => Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 3),
                                                      child: Text(
                                                          "${e.key}${e.value}",
                                                          style: GoogleFonts
                                                              .notoColorEmoji(
                                                                  fontSize:
                                                                      18)),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.comment_outlined,
                                                size: 22),
                                            onPressed: () =>
                                                _openComments(postDoc.id),
                                          ),
                                          Text("$commentCount",
                                              style: const TextStyle(
                                                  color: Colors.grey)),
                                          const SizedBox(width: 6),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
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
      floatingActionButton: GestureDetector(
        onTap: _openNewPost,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child: Image.asset(
              'assets/icons/heart.png',
              width: 32,
              height: 32,
            ),
          ),
        ),
      ),
    );
  }
}
