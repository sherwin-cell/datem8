import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/profile_modal.dart';
import 'package:datem8/widgets/setting_widget.dart';
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
      if (!doc.exists)
        return {'name': 'Unknown', 'profilePic': '', 'uid': userId};
      final data = doc.data()!;
      return {
        'name': "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}",
        'profilePic': data['profilePic'] ?? '',
        'uid': data['uid'] ?? userId,
      };
    } catch (_) {
      return {'name': 'Unknown', 'profilePic': '', 'uid': userId};
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
    final theme = Theme.of(context);

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(context, e),
                    child: Text(e,
                        style: GoogleFonts.notoColorEmoji(fontSize: 36)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

  void _showProfileModal(BuildContext context, Map<String, dynamic> user) {
    showProfileModal(context,
        userData: user, cloudinaryService: widget.cloudinaryService);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsRef =
        _firestore.collection('posts').orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          "Explore",
          style: GoogleFonts.readexPro(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          SettingsIconButton(
            cloudinaryService: widget.cloudinaryService,
            userId: FirebaseAuth.instance.currentUser!.uid,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: theme.colorScheme.secondary,
        child: StreamBuilder<QuerySnapshot>(
          stream: postsRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                    color: theme.colorScheme.secondary),
              );
            }

            final posts = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final data = post.data() as Map<String, dynamic>;
                final caption = data['caption'] ?? "";
                final userId = data['userId'] ?? "";
                final createdAt = (data['createdAt'] is Timestamp)
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now();

                final images = data['imageUrls'] != null
                    ? List<String>.from(data['imageUrls'])
                    : data['imageUrl'] != null
                        ? [data['imageUrl']]
                        : [];

                final currentPage = _currentPages[post.id] ?? 0;

                return FutureBuilder<Map<String, dynamic>>(
                  future: _getUserInfo(userId),
                  builder: (context, u) {
                    final user = u.data ??
                        {'name': 'Unknown', 'profilePic': '', 'uid': userId};

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: theme.brightness == Brightness.light
                            ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // USER INFO
                          ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            leading: GestureDetector(
                              onTap: () => _showProfileModal(context, user),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    theme.colorScheme.surfaceVariant,
                                backgroundImage: user['profilePic'] != ""
                                    ? NetworkImage(user['profilePic'])
                                    : null,
                                child: user['profilePic'] == ""
                                    ? Icon(Icons.person,
                                        color: theme.iconTheme.color)
                                    : null,
                              ),
                            ),
                            title: GestureDetector(
                              onTap: () => _showProfileModal(context, user),
                              child: Text(
                                user['name'],
                                style: GoogleFonts.readexPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            subtitle: Text(
                              DateFormat.yMMMd().add_jm().format(createdAt),
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),

                          // CAPTION
                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                caption,
                                style: GoogleFonts.readexPro(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),

                          // IMAGES
                          if (images.isNotEmpty)
                            Column(
                              children: [
                                SizedBox(
                                  height: 260,
                                  child: PageView.builder(
                                    itemCount: images.length,
                                    onPageChanged: (p) => setState(
                                        () => _currentPages[post.id] = p),
                                    itemBuilder: (_, i) => ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        images[i],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                                if (images.length > 1)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children:
                                          List.generate(images.length, (i) {
                                        final active = i == currentPage;
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          height: 8,
                                          width: active ? 22 : 8,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? theme.colorScheme.secondary
                                                : theme.dividerColor,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                              ],
                            ),

                          // REACTIONS + COMMENTS
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: post.reference.snapshots(),
                              builder: (context, snap) {
                                if (!snap.hasData) return const SizedBox();
                                final postData =
                                    snap.data!.data() as Map<String, dynamic>;
                                final reactions = Map<String, dynamic>.from(
                                    postData['reactions'] ?? {});
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                final userReaction = reactions[uid] ?? '';

                                final counts = <String, int>{};
                                for (var e in reactions.values)
                                  counts[e] = (counts[e] ?? 0) + 1;

                                return StreamBuilder<QuerySnapshot>(
                                  stream: post.reference
                                      .collection('comments')
                                      .snapshots(),
                                  builder: (context, cSnap) {
                                    final commentCount =
                                        cSnap.data?.docs.length ?? 0;

                                    return Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _updateReaction(post.id, '❤️'),
                                          onLongPress: () async {
                                            final emoji =
                                                await _showEmojiPicker(context);
                                            if (emoji != null)
                                              _updateReaction(post.id, emoji);
                                          },
                                          child: Text(
                                              userReaction.isNotEmpty
                                                  ? userReaction
                                                  : "❤️",
                                              style: GoogleFonts.notoColorEmoji(
                                                  fontSize: 24)),
                                        ),
                                        const SizedBox(width: 8),
                                        if (counts.isNotEmpty)
                                          Row(
                                            children: counts.entries
                                                .map((e) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 6),
                                                      child: Text(
                                                          "${e.key}${e.value}",
                                                          style: GoogleFonts
                                                              .notoColorEmoji(
                                                                  fontSize:
                                                                      18)),
                                                    ))
                                                .toList(),
                                          ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () => _openComments(post.id),
                                          child: Row(
                                            children: [
                                              Icon(Icons.comment_outlined,
                                                  size: 22,
                                                  color: theme.iconTheme.color),
                                              const SizedBox(width: 4),
                                              Text("$commentCount",
                                                  style: theme
                                                      .textTheme.bodySmall),
                                            ],
                                          ),
                                        ),
                                      ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondaryContainer,
        onPressed: _openNewPost,
        child: Image.asset('assets/icons/heart.png', width: 32, height: 32),
      ),
    );
  }
}
