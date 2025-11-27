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

  // ------------------ REFRESH ------------------
  Future<void> _refreshPosts() async => setState(() {});

  // ------------------ FETCH USER INFO ------------------
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists)
        return {'name': 'Unknown', 'profilePic': '', 'uid': userId};

      final data = doc.data()!;
      return {
        'name': "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim(),
        'profilePic': data['profilePic'] ?? '',
        'uid': data['uid'] ?? userId,
      };
    } catch (_) {
      return {'name': 'Unknown', 'profilePic': '', 'uid': userId};
    }
  }

  // ------------------ UPDATE REACTION ------------------
  Future<void> _updateReaction(String postId, String reaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((t) async {
      final snapshot = await t.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      if (reactions[user.uid] == reaction) {
        reactions.remove(user.uid);
      } else {
        reactions[user.uid] = reaction;
      }

      t.update(ref, {'reactions': reactions});
    });
  }

  // ------------------ REACTION PICKER ------------------
  Future<String?> _showReactionPicker(BuildContext context) async {
    final reactions = [
      {'icon': Icons.favorite_border}, // heart outline
      {'emoji': '😆'},
      {'emoji': '😮'},
      {'emoji': '😢'},
      {'emoji': '😡'},
    ];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: reactions.map((item) {
              final isIcon = item.containsKey('icon');

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context, isIcon ? '❤️' : item['emoji']);
                },
                child: isIcon
                    ? Icon(
                        item['icon'] as IconData,
                        size: 36,
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    : Text(
                        item['emoji'] as String,
                        style: GoogleFonts.notoColorEmoji(fontSize: 36),
                      ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ------------------ COMMENTS ------------------
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

  // ------------------ NEW POST ------------------
  void _openNewPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewPostPage(cloudinaryService: widget.cloudinaryService),
      ),
    );
  }

  // ------------------ PROFILE MODAL ------------------
  void _showProfileModal(BuildContext context, Map<String, dynamic> user) {
    showProfileModal(
      context,
      userData: user,
      cloudinaryService: widget.cloudinaryService,
    );
  }

  // ------------------ BUILD ------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsRef =
        _firestore.collection('posts').orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
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
            if (!snapshot.hasData)
              return Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.secondary));

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

                // Ensure images are List<String>
                final images = <String>[];
                if (data['imageUrls'] != null && data['imageUrls'] is List) {
                  images.addAll(List<String>.from(
                      data['imageUrls'].map((e) => e.toString())));
                } else if (data['imageUrl'] != null) {
                  images.add(data['imageUrl'].toString());
                }

                final currentPage = _currentPages[post.id] ?? 0;

                return FutureBuilder<Map<String, dynamic>>(
                  future: _getUserInfo(userId),
                  builder: (context, snap) {
                    final user = snap.data ??
                        {'name': 'Unknown', 'profilePic': '', 'uid': userId};
                    return _buildPostCard(
                      theme: theme,
                      post: post,
                      user: user,
                      caption: caption,
                      createdAt: createdAt,
                      images: images,
                      currentPage: currentPage,
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

  // ------------------ POST CARD ------------------
  Widget _buildPostCard({
    required ThemeData theme,
    required DocumentSnapshot post,
    required Map<String, dynamic> user,
    required String caption,
    required DateTime createdAt,
    required List<String> images,
    required int currentPage,
  }) {
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: GestureDetector(
              onTap: () => _showProfileModal(context, user),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage: user['profilePic'] != ''
                    ? NetworkImage(user['profilePic'])
                    : null,
                child: user['profilePic'] == ''
                    ? Icon(Icons.person, color: theme.iconTheme.color)
                    : null,
              ),
            ),
            title: Text(user['name'],
                style: GoogleFonts.readexPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color)),
            subtitle: Text(DateFormat.yMMMd().add_jm().format(createdAt),
                style: GoogleFonts.readexPro(
                    fontSize: 12, color: theme.textTheme.bodySmall?.color)),
          ),

          // CAPTION
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(caption,
                  style: GoogleFonts.readexPro(
                      fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
            ),

          // IMAGES
          if (images.isNotEmpty)
            Column(
              children: [
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (p) =>
                        setState(() => _currentPages[post.id] = p),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(images[i],
                          fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        final active = i == currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: active ? 22 : 8,
                          decoration: BoxDecoration(
                            color: active
                                ? theme.colorScheme.secondary
                                : theme.dividerColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),

          // REACTIONS + COMMENTS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: StreamBuilder<DocumentSnapshot>(
              stream: post.reference.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();

                final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                final reactions =
                    Map<String, dynamic>.from(data['reactions'] ?? {});
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final userReaction = reactions[uid] ?? '';

                // Count reactions
                final counts = <String, int>{};
                for (var e in reactions.values)
                  counts[e] = (counts[e] ?? 0) + 1;

                return Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _updateReaction(post.id, '❤️'),
                            onLongPress: () async {
                              final selected =
                                  await _showReactionPicker(context);
                              if (selected != null)
                                _updateReaction(post.id, selected);
                            },
                            child: Text(
                                userReaction.isNotEmpty ? userReaction : '♡',
                                style:
                                    GoogleFonts.notoColorEmoji(fontSize: 24)),
                          ),
                          const SizedBox(width: 8),
                          if (counts.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: counts.entries
                                  .map((e) => Text("${e.key}${e.value}",
                                      style: GoogleFonts.notoColorEmoji(
                                          fontSize: 18)))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openComments(post.id),
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            post.reference.collection('comments').snapshots(),
                        builder: (context, cSnap) {
                          final count = cSnap.data?.docs.length ?? 0;
                          return Row(
                            children: [
                              Icon(Icons.comment_outlined,
                                  size: 22, color: theme.iconTheme.color),
                              const SizedBox(width: 4),
                              Text("$count", style: theme.textTheme.bodySmall),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
