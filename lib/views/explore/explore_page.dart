import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/views/post/new_post_page.dart';
import 'package:intl/intl.dart';

class ExplorePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const ExplorePage({super.key, required this.cloudinaryService});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();

  void _openNewPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewPostPage(cloudinaryService: widget.cloudinaryService),
      ),
    );
  }

  Future<void> _refreshPosts() async {
    setState(() {});
  }

  Future<Map<String, String>> _getAuthorInfo(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return {
        'name': data['name'] ?? 'Unknown',
        'avatar': data['profilePic'] ?? '',
      };
    }
    return {'name': 'Unknown', 'avatar': ''};
  }

  Future<Map<String, String>> _getCurrentUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {'name': 'Unknown', 'avatar': ''};
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return {
        'name': data['name'] ?? 'Unknown',
        'avatar': data['profilePic'] ?? '',
      };
    }
    return {'name': 'Unknown', 'avatar': ''};
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
                // Top "New Post" card
                if (index == 0) {
                  return FutureBuilder<Map<String, String>>(
                    future: _getCurrentUserInfo(),
                    builder: (context, userSnapshot) {
                      final userData = userSnapshot.data ??
                          {'name': 'Unknown', 'avatar': ''};
                      final avatarUrl = userData['avatar'] ?? '';

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
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Share something you're grateful for...",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                // Regular post cards
                final postData =
                    posts[index - 1].data() as Map<String, dynamic>;
                final caption = postData['caption'] ?? '';
                final userId = postData['userId'] ?? '';
                final timestamp = postData['createdAt'] != null
                    ? (postData['createdAt'] as Timestamp).toDate()
                    : DateTime.now();

                // Handle single and multiple images
                List<String> images = [];
                if (postData['imageUrls'] != null) {
                  images =
                      (postData['imageUrls'] as List<dynamic>).cast<String>();
                } else if (postData['imageUrl'] != null) {
                  images = [postData['imageUrl'] as String];
                }

                return FutureBuilder<Map<String, String>>(
                  future: _getAuthorInfo(userId),
                  builder: (context, authorSnapshot) {
                    final author = authorSnapshot.data ??
                        {'name': 'Unknown', 'avatar': ''};
                    final avatarUrl = author['avatar'] ?? '';
                    final name = author['name'] ?? 'Unknown';

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                DateFormat.yMMMd().add_jm().format(timestamp)),
                          ),

                          // Images with carousel and overlay +N
                          if (images.isNotEmpty)
                            Column(
                              children: [
                                SizedBox(
                                  height: 250,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount:
                                        images.length > 3 ? 3 : images.length,
                                    itemBuilder: (context, i) {
                                      bool overlay =
                                          images.length > 3 && i == 2;
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              images[i],
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          if (overlay)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black38,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '+${images.length - 2}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 32,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Dots indicator for up to 3 images
                                if (images.length > 1)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      images.length > 3 ? 3 : images.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                          // Caption
                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(caption,
                                  style: const TextStyle(fontSize: 16)),
                            ),

                          // Action Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.favorite_border),
                                SizedBox(width: 16),
                                Icon(Icons.comment_outlined),
                                SizedBox(width: 16),
                                Icon(Icons.share_outlined),
                              ],
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
